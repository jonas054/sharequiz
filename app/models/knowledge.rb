# This class holds information about the result for a certain query
# pertaining to a certain user.
class Knowledge < ActiveRecord::Base
  belongs_to :user
  belongs_to :query

  validates_presence_of :user_id, :query_id
  validates_uniqueness_of :query_id, :scope => :user_id
  
  # This formula tries to produce a well weighted total score based on
  # number of correct answers, number of incorrect answers, and time
  # since the last correct answer.
  def score
    seconds_passed = Time.now.to_i - Integer(time_for_last_correct_answer || 0)
    wrong_answers = nr_of_answers - nr_of_correct_answers
    # Scores grow linearly with number of correct answers, but
    # geometrically with number of wrong answers. That's a way to
    # ensure that more attention is paid to problem areas.
    x = Integer(nr_of_correct_answers - wrong_answers ** 1.5)
    if x < 0
      x # Time is not a factor when the score is negative.
    else
      10_000_000 * x / (seconds_passed + 500_000)
    end
  end

  FullKnowledgeScore = 15

  def self.score_group(s)
    if    s == 0                 then :none
    elsif s <= 0                 then :negative
    elsif s < FullKnowledgeScore then :partial
    else                              :full
    end
  end

  def self.statistic_for(user_id, lang_id)
    wordcount =
      find(:all,
           :joins => ', lessons, queries',
           :conditions =>
           [ "knowledges.user_id     = #{user_id}",
             "nr_of_correct_answers != 0",
             "query_id               = queries.id",
             "lesson_id              = lessons.id",
             "(question_lang_id = #{lang_id} OR answer_lang_id = #{lang_id})"
           ].join(" AND ")).map { |k|
      [0, [FullKnowledgeScore, k.score].min].max.to_f / FullKnowledgeScore
    }
    Statistic.new(:user_id => user_id, :language_id => lang_id,
                  :wordcount => wordcount.sum.to_i)
  end
end
