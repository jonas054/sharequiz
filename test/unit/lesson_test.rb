require 'test_helper'

class LessonTest < ActiveSupport::TestCase
  test "ok lesson" do
    create_example "Food and drink"
  end

  test "lesson with no data" do
    lesson = Lesson.new
    cbb = "can't be blank"
    nan = "is not a number"
    check_save_error lesson, :name, cbb
    check_save_error lesson, :answer_lang_id, [cbb, nan]
    check_save_error lesson, :question_lang_id, [cbb, nan]
  end


  test "duplicate lesson name" do
    create_example "Traffic"
    check_save_errors(Lesson.new(:name => "Traffic", :question_lang_id => 2,
                                 :answer_lang_id => 1),
                      ["Name has already been taken"])
  end

  private

  def create_example(name)
    Lesson.create!(:name => name, :question_lang_id => 1,
                   :answer_lang_id => 2)    
  end
end
