# -*- coding: utf-8 -*-
require 'test_helper'

class QueryTest < ActiveSupport::TestCase
  def test_stripping
    # Soft hyphen
    q = Query.create! :question => '美容院 ', :answer => ' skönhets­salong'
    assert_equal '美容院', q.question
    assert_equal 'skönhetssalong', q.answer

    # Spaces
    q = Query.create! :question => 'shoe  horn ', :answer => ' skohorn'
    assert_equal 'shoe horn', q.question
    assert_equal 'skohorn', q.answer
  end

  def test_query_with_no_data
    query = Query.new
    [:question, :answer].each { |sym|
      check_save_error query, sym, "can't be blank"
    }
  end

  def test_choose
    lsn = Lesson.create!(:name => 'test',
                         :question_lang_id =>
                         Language.find_by_english_name('Chinese').id,
                         :answer_lang_id   =>
                         Language.find_by_english_name('Swedish').id)
    ['=', # equals
     ' = ', # equals with spaces
     '＝', # Chinese equals
     ' ＝ ' # Chinese equals with spaces
    ].each { |eq|
      check_choose_with_equals ['本子', '笔记本'], lsn, eq
    }
   end

  def check_choose_with_equals(question_alt, lsn, equals)
    answer_alt = %w(anteckningsbok anteckningsblock)
    Query.create!(:question  => question_alt.join(equals),
                  :answer    => answer_alt.join(equals),
                  :lesson_id => lsn.id)
    check_choice lsn, question_alt, answer_alt, :chi, '不是', false
    check_choice lsn, answer_alt, question_alt, :swe, 'inte', true
  end

  def check_choice(lsn, answer_alt, alt, lang, local_not, is_rev)
    jonas = users(:jonas)
    jonas.native_language = languages(lang).id
    jonas.save!
    q, answer_ix = Query.choose [lsn], jonas.id, is_rev
    assert(answer_alt.map { |a|
             "#{a} (#{local_not} #{(alt - [q.effective_answer]).join(', ')})"
           }.member?(q.effective_question),
           "'#{q.effective_question}' not found in [#{answer_alt.join(', ')}]")
    assert_equal alt[answer_ix], q.effective_answer
  end
  
  def test_translate_pinyin
    check_pinyin 'zhong1',     'zhōng'
    check_pinyin 'duo1',       'duō'
    check_pinyin 'dou1',       'dōu'
    check_pinyin 'fei1',       'fēi'
    check_pinyin 'ban1',       'bān'
    check_pinyin 'ban1 jia1',  'bān jiā'
    check_pinyin 'guo2',       'guó'
    check_pinyin 'ren2',       'rén'
    check_pinyin 'niu2',       'niú'
    check_pinyin 'wo3',        'wǒ'
    check_pinyin 'you3',       'yǒu'
    check_pinyin 'suo3',       'suǒ'
    check_pinyin 'ni3',        'nǐ'
    check_pinyin 'xi3huan1',   'xǐhuān'
    check_pinyin 'xi3 huan1',  'xǐ huān'
    check_pinyin 'xue3',       'xuě'
    check_pinyin 'qing3 wen4', 'qǐng wèn'
    check_pinyin 'kan4',       'kàn'
    check_pinyin 'lü4 se4',    'lǜ sè'
    check_pinyin 'lv4 se4',    'lǜ sè'
    check_pinyin 'hui4',       'huì'
    check_pinyin 'xīng qī; zhou1; li3 bai4', 'xīng qī; zhōu; lǐ bài'
    check_pinyin 'yu2',        'yú'
    check_pinyin 'lia3',       'liǎ'
    check_pinyin 'qian2 tian1','qián tiān'
    check_pinyin 'ba4 ba0',    'bà ba'
    check_pinyin 'ba4 ba5',    'bà ba'
  end

  def check_pinyin(numbered, accented)
    q =
      Query.new(:question => '我',
                :answer => 'jag; mig',
                :clue => numbered,
                :lesson => Lesson.new(:question_lang_id => languages(:chi).id,
                                      :answer_lang_id => languages(:eng).id))
    q.translate_pinyin
    assert_equal accented, q.clue
  end

  def test_duplicates
    french, swedish, chinese = 1, 2, 3

    goddag, _ = create_lesson_with_one_query(french, swedish, "Goddag",
                                             "comment", "hur")

    fraser1, zenme = create_lesson_with_one_query(swedish, chinese, "Fraser1",
                                                  "hur", "怎么 = 如何")

    fraser2, ruhe = create_lesson_with_one_query(chinese, swedish, "Fraser2",
                                                 "如何", "hur")

    # Should have no duplicates since languages don't match.
    assert_equal [[], []], Query.duplicates_of(goddag)

    # Languages match so this is a duplicate.
    assert_equal [[zenme], [ruhe.id]], Query.duplicates_of(fraser2)
    assert_equal [[ruhe], [zenme.id]],  Query.duplicates_of(fraser1)
  end

  def create_lesson_with_one_query(question_lang_id, answer_lang_id, name,
                                   question, answer)
    lesson = Lesson.create!(:name             => name,
                            :question_lang_id => question_lang_id,
                            :answer_lang_id   => answer_lang_id)
    query = Query.create!(:question  => question,
                          :answer    => answer,
                          :lesson_id => lesson.id)
    [lesson, query]
  end
  private :create_lesson_with_one_query

  def test_possible_with_all_special_characters
    check_possible(answer('gå; (att) komma/återvända hem (igen)'),
                   'gå',
                   'att komma hem igen',
                   'att komma hem',
                   'att återvända hem igen',
                   'att återvända hem',
                   'komma hem igen',
                   'komma hem',
                   'återvända hem igen',
                   'återvända hem')
  end

  def test_possible_sentence_with_optional_part_of_word
    check_possible(answer('Jag arbetar/jobbar på universitet(et).'),
                   'Jag arbetar på universitetet.',
                   'Jag arbetar på universitet.',
                   'Jag jobbar på universitetet.',
                   'Jag jobbar på universitet.')
  end

  def test_possible_slash_paren_combination
    ['person(er)/människa/människor',
     'människa/människor/person(er)',
     'människa/person(er)/människor']. each { |a|
      check_possible(answer(a), 'människa', 'människor', 'person', 'personer')
      check_possible(answer('äldre ' + a),
                     'äldre människa',
                     'äldre människor',
                     'äldre person',
                     'äldre personer')
    }
  end

  def test_possible_optional_part_of_word
    check_possible(answer('kyckling(kött)'),
                   'kycklingkött',
                   'kyckling')
  end

  def test_possible_optional_part_of_word_2
    check_possible(answer('Vill du inte ha (Coca-)Cola eller något?'),
                   'Vill du inte ha Coca-Cola eller något?',
                   'Vill du inte ha Cola eller något?')
    check_possible(answer('Vill du inte ha (Coca-)Cola?'),
                   'Vill du inte ha Coca-Cola?',
                   'Vill du inte ha Cola?')
  end

  def test_possible_sentence_with_slash
    check_possible(answer('Här är 35/trettiofem yuan/RMB.'),
                   'Här är 35 yuan.',
                   'Här är trettiofem yuan.',
                   'Här är 35 RMB.',
                   'Här är trettiofem RMB.')
  end

  def test_possible_double_sentence_with_slashes
    check_possible(answer('Foo bar/baz? Smurf bip/bop!'),
                   'Foo bar? Smurf bip!',
                   'Foo baz? Smurf bip!',
                   'Foo bar? Smurf bop!',
                   'Foo baz? Smurf bop!')
  end


  def test_possible_two_sentences
    check_possible(answer('Vad heter du?; Vad är ditt namn?'),
                   'Vad heter du?',
                   'Vad är ditt namn?')
  end

  def test_possible_many_parens
    check_possible(answer('(a) (modal) (particle) (indicating) (a) question'),
                   "a a question",
                   "a indicating a question",
                   "a indicating question",
                   "a modal a question",
                   "a modal indicating a question",
                   "a modal indicating question",
                   "a modal particle a question",
                   "a modal particle indicating a question",
                   "a modal particle indicating question",
                   "a modal particle question",
                   "a modal question",
                   "a particle a question",
                   "a particle indicating a question",
                   "a particle indicating question",
                   "a particle question",
                   "a question",
                   "indicating a question",
                   "indicating question",
                   "modal a question",
                   "modal indicating a question",
                   "modal indicating question",
                   "modal particle a question",
                   "modal particle indicating a question",
                   "modal particle indicating question",
                   "modal particle question",
                   "modal question",
                   "particle a question",
                   "particle indicating a question",
                   "particle indicating question",
                   "particle question",
                   "question")
  end

  def test_possible_slashes_and_semicolon
    check_possible(answer('sluta jobbet/jobba;sluta arbetet/arbeta'),
                   'sluta jobbet',
                   'sluta jobba',
                   'sluta arbetet',
                   'sluta arbeta')
  end

  def test_possible_more_than_2_alt
    check_possible(answer('sluta jobbet/jobba/arbetet/arbeta'),
                   'sluta jobbet',
                   'sluta jobba',
                   'sluta arbetet',
                   'sluta arbeta')
  end

  def test_possible_more_than_2_alt_within_paren
    check_possible(answer('sluta (jobbet/jobba/arbetet/arbeta)'),
                   'sluta jobbet',
                   'sluta jobba',
                   'sluta arbetet',
                   'sluta arbeta',
                   'sluta')
  end

  def test_possible_latin_equals
    check_possible(answer('本子=笔记本'),
                   '本子',
                   '笔记本')
  end

  def test_possible_chinese_equals
    check_possible(answer('本子＝笔记本'),
                   '本子',
                   '笔记本')
  end

  def test_possible_chinese_parentheses
    check_possible(answer('什么样 = 哪(一)种'),
                   '什么样',
                   '哪一种',
                   '哪种')
  end

  
  def test_answer_checking
    query = answer '(att) komma/återvända hem (igen)'
    check_possible(query,
                   'att komma hem igen',
                   'att komma hem',
                   'att återvända hem igen',
                   'att återvända hem',
                   'komma hem igen',
                   'komma hem',
                   'återvända hem igen',
                   'återvända hem')
    ['att', 'igen'].each { |word| assert !query.answer_ok?(word, false, nil) }
  end

  def test_possible_parentheses_at_end_of_sentence
    check_possible(answer('Hon är 9 år (gammal).'),
                   'Hon är 9 år.',
                   'Hon är 9 år gammal.')
  end

  def test_slash_with_parentheses
    check_possible(answer('ren(t); klar(t)/tydlig(t)'),
                   'ren',
                   'rent',
                   'klar',
                   'klart',
                   'tydlig',
                   'tydligt')
  end

  # TODO -  Add this functionality.
#   def test_possible_parentheses_with_slash_inside
#     check_possible(answer('åter(vända/lämna)'),
#                    'åter',
#                    'återvända',
#                    'återlämna')
#   end
  
  def test_possible_chinese
    # Note: Chinese slash, semi-colon, and parentheses.
    check_possible(answer('天／日'), '天', '日')
    check_possible(answer('时（间）；时（候)'), '时', '时间', '时候')
    check_possible(answer('有（的）时候'), '有时候', '有的时候')
  end

  def test_timing
    q = answer('gå; (att) komma/återvända hem (igen)')
    real = Benchmark.realtime { q.possible }
    assert real < 0.2, "too slow: #{real}"
  end

  def test_knowledge
    q = Query.create! :question => 'Horse', :answer => 'Häst'
    jonas = users(:jonas).id
    k = q.knowledge jonas
    assert_equal 0, k.nr_of_answers

    assert_equal false, q.answer_ok?(nil, false, nil)
    k.nr_of_answers += 2
    k.save!
    assert_equal 2, q.knowledge(jonas).nr_of_answers
  end
  
  private

  def answer(s)
    Query.create! :question => 'blablabla', :answer => s
  end

  def check_possible(query, *expected)
    assert_equal expected.sort, query.possible.sort
    expected.each { |s| assert query.answer_ok?(s, false, nil) }
  end
end
