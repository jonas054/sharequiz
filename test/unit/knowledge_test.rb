require 'test_helper'

class KnowledgeTest < ActiveSupport::TestCase
  test "different amounts of passed time" do
    previous = 1_000_000
    [1.hour, 1.week, 1.month, 1.year, 10.years].each { |time|
      s = Knowledge.new(:nr_of_answers => 10, :nr_of_correct_answers => 8,
                        :time_for_last_correct_answer => time.ago).score
      assert s < previous, "score for #{time}s should be lower than previous"
      previous = s
    }
  end

  # Check that new questions get a higher score than questions that
  # the user has had problems with. That way, the difficult questions
  # are repeated a few times before new questions are tried.
  test "brand new question" do
    k0 = Knowledge.new(:nr_of_answers => 0, :nr_of_correct_answers => 0)
    k1 = Knowledge.new(:nr_of_answers => 1, :nr_of_correct_answers => 0,
                       :time_for_last_correct_answer => 1.minute.ago)
    assert(k0.score > k1.score,
           "A new questions should have a higher score than a question with " +
           "one incorrect answer and no correct answers")
  end

  # Since new questions should have a score of 0, we use negative
  # scores for questions with more incorrect answers than correct.
  test "negative score" do
    k = Knowledge.new(:nr_of_answers => 3, :nr_of_correct_answers => 1)
    assert k.score < 0
  end

  test "long time passed" do
    {
      10 => 16.weeks,
      9  => 3.months,
      8  => 8.weeks,
      7  => 1.week
    }.each { |corr, time|
      assert_equal(9,
                   Knowledge.new(:nr_of_answers => 10,
                                 :nr_of_correct_answers => corr,
                                 :time_for_last_correct_answer =>
                                 time.ago).score,
                   "#{corr}/10 after #{time}s")
    }
  end
end
