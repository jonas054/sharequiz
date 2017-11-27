require 'test_helper'

class QueriesControllerTest < ActionController::TestCase
  test "should get edit" do
    q = queries :shoe_sko
    get :edit, :id => q.id, :lesson_id => q.lesson_id
    assert_redirected_to(:controller => 'lessons',
                         :action     => 'edit',
                         :id         => q.lesson_id,
                         :query_id   => q.id)
  end

  test "should destroy query" do
    q = queries :shoe_sko
    assert_difference('Query.count', -1) {
      delete :destroy, :id => q.id, :lesson_id => q.lesson_id
    }
    assert_redirected_to(:controller => 'lessons',
                         :action     => 'edit',
                         :id         => q.lesson_id)
  end
end
