class Lesson < ActiveRecord::Base
  has_many :queries

  validates_uniqueness_of   :name
  validates_presence_of     :name, :question_lang_id, :answer_lang_id
  validates_numericality_of :question_lang_id, :only_integer => true
  validates_numericality_of :answer_lang_id,   :only_integer => true

  belongs_to :user

  def includes_language?(lang)
    lang == question_lang or lang == answer_lang
  end

  def score(user_id)
    return 0 if queries.size == 0
    Knowledge.find(:all,
                   :conditions => {
                     :user_id  => user_id,
                     :query_id => queries }).map { |k|
      k.score
    }.sum / queries.size
  end

  def effective_question_lang(is_reversed)
    if is_reversed then answer_lang else question_lang end
  end

  def effective_answer_lang(is_reversed)
    if is_reversed then question_lang else answer_lang end
  end

  def question_lang() Language.find question_lang_id end
  def answer_lang()   Language.find answer_lang_id   end
end
