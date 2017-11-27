require 'test_helper'
require 'action_view/test_case'

class LessonsHelperTest < ActionView::TestCase
  include LessonsHelper

  def test_history_graph
    @goal = 10
    assert_equal('<img class="chart" src="http://chart.apis.google.com/chart' +
                 '?chco=000000,00A000,A0A000' +
                 '&chd=t:1,0,0|40,40,30|0,2|30,30|0,1|40,40' +
                 '&chds=0,2,0,44' +
                 '&chg=50,0,2,5,0,0' +
                 '&chls=2,1,0|1,3,3|1,3,3' +
                 '&chm=h,B00000,0,0.114,0.5,1|h,B00000,0,0.227,0.5,1' +
                 '|h,B00000,0,0.341,0.5,1|h,B00000,0,0.455,0.5,1' +
                 '|h,B00000,0,0.568,0.5,1|h,B00000,0,0.682,0.5,1' +
                 '|h,B00000,0,0.795,0.5,1|h,B00000,0,0.909,0.5,1' +
                 '|o,3300FF,0,0,8,1|o,FFFFFF,0,0,4,1' +
                 '|o,3300FF,0,1,8,1|o,FFFFFF,0,1,4,1' +
                 '|o,3300FF,0,2,6,1' +
                 '&chma=0,30,5,15' +
                 '&chs=600x500' +
                 '&cht=lxy' +
                 '&chxr=0,0,44' +
                 '&chxt=r' +
                 '" />',
                 history_graph([0,1,2], [40,40,30]))
  end

  def test_horizontal_lines
    { 100  => 10,
      300  => 6,
      900  => 9,
      2700 => 5 }.each {
      |scale, exp_lines|
      assert_equal(exp_lines, horizontal_lines(scale).scan(/h,B00000/).size)
    }
  end
  
  def test_progress_square
    assert_equal('<td bgcolor="red" height="10" width="10" />',
                 progress_square('red'))
  end
end
