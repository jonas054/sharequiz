# -*- coding: utf-8 -*-
require 'pythonic_privates'

class Query < ActiveRecord::Base
  extend PythonicPrivates

  belongs_to :lesson
  before_save :_strip_all, :possible
  validates_presence_of :question, :answer

  # Removes leading spaces, trailing spaces, and soft hyphens.
  # Replaces multiple spaces with a single space.
  def _strip_all
    [question, answer, clue].compact.each { |f|
      f.strip!
      f.gsub!(/­/, '')
      f.gsub!(/\s{2,}/, ' ')
    }
  end

  # Returns total number of queries in the given lessons.
  def self.count_for(lessons)
    Query.count :conditions => { :lesson_id => lessons }
  end

  # Returns the Knowledge object associated with this query and the given user.
  def knowledge(user_id)
    k = Knowledge.find(:first,
                       :conditions => { :user_id => user_id, :query_id => id })
    k = Knowledge.create :query_id => id, :user_id => user_id if k.nil?
    k
  end

  def save_with_new_knowledge(user_id)
    translate_pinyin
    save!
    Knowledge.create :query_id => id, :user_id => user_id
  end

  def answer_ok?(ans, is_reversed, answer_index)
    return false if ans.nil?
    self.is_rev = is_reversed
    s = if answer_index
          Query.top_level_split(effective_answer)[answer_index.to_i]
        else
          effective_answer
        end
    possible(s).include? ans.strip
  end

  attr_accessor :is_rev

  def effective_answer()   is_rev ? question : answer   end
  def effective_question() is_rev ? answer   : question end

  def effective_answer=(a)
    send "#{is_rev ? 'question' : 'answer'}=", a
  end

  def effective_question=(a)
    send "#{is_rev ? 'answer' : 'question'}=", a
  end

  def translate_pinyin
    return if clue !~ /[0-5]/
    zw = Language.find_by_english_name("Chinese") or return

    if [lesson.question_lang_id, lesson.answer_lang_id].member? zw.id
      self.clue = clue.gsub(/([iu])([aoeiu])([ngr]*)([0-5])/i) {
        # If double vowel starting with i or u, accent goes on second vowel.
        $1 + _accent($2, $4.to_i) + $3
      }.gsub(/([aoeiuüvÜV])([oeiu]?[ngr]*)([0-5])/i) {
        # Otherwise accent goes on first (or only) vowel.
        _accent($1, $3.to_i) + $2
      }

      # The assignment of self.clue is necessary for ActiveRecord#save!() to
      # know that the field has been updated. If we only used gsub!(), we would
      # have to call Query.update() explicitly.
    end
  end

  def _accent(s, tone_nr)
    orig = %w'a e i o u ü v A E I O U Ü V'
    acc = [orig,
           %w'ā ē ī ō ū ǖ ǖ Ā Ē Ī Ō Ū Ǖ Ǖ',
           %w'á é í ó ú ǘ ǘ Á É Í Ó Ú Ǘ Ǘ',
           %w'ǎ ě ǐ ǒ ǔ ǚ ǚ Ǎ Ě Ǐ Ǒ Ǔ Ǚ Ǚ',
           %w'à è ì ò ù ǜ ǜ À È Ì Ò Ù Ǜ Ǜ',
           orig][tone_nr]
    orig.each_with_index { |w,i| s.sub! w, acc[i] }
    s
  end

  # Choose a query that the user has a relatively bad knowledge of, is
  # not the same as the previous query, and has the same answer
  # language as the previous.
  def self.choose(lessons, user_id, is_reversed, previous = nil)
    queries = Query.find :all, :conditions => { :lesson_id => lessons }
    scores = Hash.new 0
    Knowledge.find(:all,
                   :conditions => {
                     :user_id  => user_id,
                     :query_id => queries }).each { |k|
      scores[k.query_id] = k.score
    }
    sorted    = queries.sort_by { |q| scores[q.id] }
    user      = User.find user_id
    scrambled = sorted[0, user.quiz_length].sort_by { rand }
    choice =
      if previous.nil?
        scrambled.first
      else
        scrambled.find { |q|
          q.id != previous.id and
          q.answer_lang_id(is_reversed) == previous.answer_lang_id(is_reversed)
        } or sorted.first
      end
    choice.is_rev = is_reversed
    choice.effective_question =
      choice.effective_question.split(/\s*[＝=]\s*/).random_element
    if choice.effective_answer =~ /[＝=]/ and
        choice.answer_lang_id(is_reversed) != user.native_language
      alternatives = choice.effective_answer.split(/\s*[＝=]\s*/)
      answer_index = rand alternatives.size
      choice.effective_answer = alternatives.delete_at answer_index
      choice.effective_question = choice.effective_question + " (" +
        case choice.lesson.effective_question_lang(is_reversed).english_name
        when 'Swedish' then 'inte'
        when 'Chinese' then '不是'
        else                'not'
        end + ' ' + alternatives.join(', ') + ")"
    end
    [choice, answer_index]
  end

  def answer_lang_id(is_reversed)
    is_reversed ? lesson.question_lang_id : lesson.answer_lang_id
  end

  # Find queries in the database that may contain duplicates of queries in lsn.
  def self.duplicates_of(lsn)
    all =
      Query.find(:all,
                 :include => 'lesson',
                 :conditions =>
                 "(lessons.question_lang_id = #{lsn.question_lang_id} AND " +
                 " lessons.answer_lang_id   = #{lsn.answer_lang_id}) " +
                 "OR " +
                 "(lessons.question_lang_id = #{lsn.answer_lang_id}   AND " +
                 " lessons.answer_lang_id   = #{lsn.question_lang_id})")
    poss = {}
    all.each { |q| poss[q.id] = q.possible(q.question) + q.possible(q.answer) }
    others = all.reject { |q| q.lesson_id == lsn.id }
    orig_queries = []
    duplicates = lsn.queries.map { |q|
      others.find_all { |o|
        result = poss[q.id].find { |word| poss[o.id].include? word }
        orig_queries << q.id if result
        result
      }
    }.flatten.uniq
    [duplicates, orig_queries]
  end

  # Western and Chinese special characters
  SemiColon = ';；＝=' # equals act like semicolons in answers
  LeftPar   = '\(（'
  RightPar  = '\)）'
  Slash     = '/／'
  Ending    = '\.!\?,。！？，'
  AnyPar    = LeftPar + RightPar
  Special   = SemiColon + AnyPar + Slash

  def possible(eff_answer = answer, combos = nil)
    if combos == nil
      return [eff_answer] unless eff_answer =~ /[#{Special}]/
      all = Query.top_level_split(eff_answer).map { |ans|
        possible(nil, _attach(:text => "", :remainder => ans)).map { |s|
          s.strip.gsub(/  +/, ' ')
        }.uniq
      }
      return all.flatten.uniq
    end
    return [combos[:text]].uniq if combos[:children].empty?
    result = []
    combos[:children].each { |kid|
      possible(nil, kid).each { |poss| result << (combos[:text] + poss) }
    }
    result
  end

  def _attach(node)
    before = node.dup
    node[:children] =
      case node[:remainder]
      when /^((\s*)([^#{LeftPar}\s]([^\s]*[#{Slash}])+)([^\s#{Ending}]+))(.*)/
        # word1/word2
        space, rem = $2, $6
        $1.split(%r"[#{Slash}]").map { |w|
          if w =~ /[#{LeftPar}]/
            { :text => space, :remainder => w + rem }
          else
            { :text => space + w, :remainder => rem }
          end
        }
      when /^(\s*[^#{Special}\s]*)[#{LeftPar}]([^#{AnyPar}]*)[#{RightPar}](.*)/
        # (word1[/word2])
        pre, within, post = $1, $2, $3
        first = if within =~ %r"[#{Slash}]"
                  { :text => pre, :remainder => within + post }
                else
                  { :text => pre + within, :remainder => post }
                end
        if post =~ /^[#{Ending}]/
          pre = $1 if pre =~ /^(.*)\s+$/ # Remove space before sentence ending.
        end
        [first, {:text => pre, :remainder => post}]
      when /^(\s*\S+)(.*)/
        [{ :text => $1, :remainder => $2 }]
      when ''
        []
      else
        raise "Can not parse '#{node[:remainder]}' in #{node.inspect}"
      end
    node[:children].each { |child| _attach child }
    node
  end

  def self.top_level_split(s)
    s.split(/\s*[#{SemiColon}]\s*/)
  end

  def to_s() "#{question} / #{answer}" end
end
