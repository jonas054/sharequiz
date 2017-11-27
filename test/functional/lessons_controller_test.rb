# -*- coding: utf-8 -*-
require 'test_helper'

class LessonsControllerTest < ActionController::TestCase
  def test_get_index_not_logged_in
    get :index
    assert_response :success
    assert_assigns :page_lessons
    assert_equal Lesson.count, assigns(:page_lessons).size
  end

  def test_get_index_logged_in
    Statistic.create!(:user_id     => users(:jonas).id,
                      :language_id => languages(:chi).id,
                      :wordcount   => 1000)
    get :index, {}, :user_id => users(:jonas).id
    assert_response :success
    assert assigns(:statistics).size > 0
  end

  def test_get_index_with_filters
    check_filtering({ :title_match => "second" }, "name LIKE '%second%'")
    check_filtering({ :lang1 => 2 },
                    "answer_lang_id = 2 OR question_lang_id = 2")
    check_filtering({ :lang1 => 2, :lang2 => 3 },
                    "(answer_lang_id = 2 AND question_lang_id = 3) OR " +
                    "(answer_lang_id = 3 AND question_lang_id = 2)")
    check_filtering({ :created_by => "jonas" },
                    "user_id = #{users(:jonas).id}")
  end

  def check_filtering(params, cond)
    get :index, {}, { :filter => params }
    assert_response :success
    assert_assigns :page_lessons
    assert_equal(Lesson.find(:all, :conditions => cond).size,
                 assigns(:page_lessons).size)
  end

  def test_get_index_with_sorting
    %w'name creator language'.each { |f| check_sorting f }
  end

  def check_sorting(field)
    [field, "_#{field}"].each { |f|
      get :index, :sort => f
      assert_response :success
    }
  end

  test "should get new" do
    get :new, {}, :user_id => users(:jonas).id
    assert_response :success
    assert_assigns :lesson, :languages
  end

  test "should create lesson" do
    assert_difference 'Lesson.count', 1 do
      post(:create,
           { :lesson => {
               :name             => 'Newly created',
               :answer_lang_id   => 1,
               :question_lang_id => 2 },
             :commit => "Create" },
           { :user_id => users(:jonas).id }) # session
    end
    assert_redirected_to :action => 'edit', :id => assigns(:lesson).id
  end

  test "should not create incomplete lesson" do
    assert_no_difference 'Lesson.count' do
      post(:create,
           { :lesson => {
               # name parameter missing
               :answer_lang_id   => 1,
               :question_lang_id => 2 },
             :commit => "Create" },
           :user_id => users(:jonas).id) # session
    end
    assert_response :success
    assert_template 'new'
  end

  test "should add filter" do
    already_set_params = {}
    {
      :lang1       => 1,
      :lang2       => 2,
      :created_by  => 10,
      :title_match => 'hello',
      :sort        => '_name'
    }.each {|k,v|
      get :add_filter, already_set_params.merge(:filter => {k=>v})
      already_set_params.merge! k=>v
      assert_redirected_to :action => 'index'
    }
  end

  test "should start quiz" do
    get :run, {}, :user_id => users(:jonas).id
    assert_assigns :query
  end
  
  test "should get edit" do
    get :edit, { :id => lessons(:one).id }, :user_id => users(:jonas).id
    assert_response :success
  end

  def test_answer
    check_answer 10, 'shoe', 1, 'run' # Correct answer
    check_answer 10, 'tree', 0, 'run' # Incorrect answer
    check_answer 1,  'shoe', 1, '' # Correct answer to final question
  end

  def check_answer(questions_left, given_answer, correct_answers_delta,
                   template)
    shoe_id = queries(:shoe_sko).id
    assert_difference("Knowledge.find_by_query_id(#{shoe_id})." +
                      "nr_of_correct_answers", correct_answers_delta) do
      get(:answer,
          {
            :id    => shoe_id,
            :query => { :question => 'sko', :answer => given_answer }
          },
          :user_id        => users(:jonas).id,
          :questions_left => questions_left,
          :progress       => [],
          :reversed       => false)
    end
    assert_equal questions_left-correct_answers_delta, session[:questions_left]
    assert_equal [correct_answers_delta==1],           session[:progress]
    if session[:questions_left] == 0
      assert session[:reversed]
      assert_redirected_to :action => 'index'
    end
    assert_template template
  end

  # Apparently this can happen if the browser goes to an old answer page.
  def test_answer_with_only_id
    get :answer, { :id => queries(:shoe_sko).id }, :user_id => users(:jonas).id
    assert_redirected_to :action => 'run'
  end

  # Apparently this can happen if the browser goes to an old answer page.
  def test_answer_without_user
    get :answer, :id => queries(:shoe_sko).id
    assert_redirected_to :controller => 'login', :action => 'login'
  end

  def test_update_lesson
    check_update_lesson(1, :commit => "Add",
                        :new_query => {
                          :question => "人",
                          :answer   => "man",
                          :clue     => "ren2"
                        })
    assert_equal "rén", Query.find_by_answer("man").clue
  end

  def test_edit_query
    check_update_lesson(0,
                        :commit => "Save",
                        :query_id => lesson1.queries.first.id,
                        :query_to_edit => {
                          :question => "人",
                          :answer   => "man",
                          :clue     => "ren­2 " # soft hyphen
                        })
    assert_equal "rén", Query.find_by_answer("man").clue
  end

  def check_update_lesson(delta, extra)
    queries_before = lesson1.queries.size
    assert_difference('Query.count', delta) do
      put(:update,
          {
            :id => lesson1.id
          }.merge(extra),
          :user_id => users(:jonas).id)
      assert_redirected_to :controller => 'lessons', :action => 'edit', :id => lesson1.id
    end
    assert_equal queries_before + delta, lesson1.queries.size
  end

  test "should destroy lesson" do
    assert_difference('Lesson.count', -1) do
      delete :destroy, {:id => lessons(:one).id}, :user_id => users(:jonas).id
    end
    assert_redirected_to root_path
  end

  def test_history
    get :history, {}, :user_id => users(:jonas).id
    assert_assigns :history, :goal, :page_title
  end
  
  def test_transpose
    check_query "sko", "shoe", "foot glove"
    post :transpose_qa, { :id => lessons(:one).id }, :user_id => users(:jonas).id
    assert_redirected_to :controller => 'lessons', :action => 'edit', :id => lessons(:one).id
    check_query "shoe", "sko", "foot glove"

    post :transpose_ac, { :id => lessons(:one).id }, :user_id => users(:jonas).id
    assert_redirected_to :controller => 'lessons', :action => 'edit', :id => lessons(:one).id
    check_query "shoe", "foot glove", "sko"
  end

  def test_import
    assert_difference 'Query.count', 2 do
      post(:import,
           {
             :id => lessons(:one).id,
             :csv => {
               :text =>
               "båt	boat	vessel\n" +
               "bil	car	automobile"
             }
           },
           :user_id => users(:jonas).id)
    end
    assert_redirected_to(:controller => 'lessons',
                         :action     => 'edit',
                         :id         => lessons(:one).id)
  end
  
  private #------------------------------------------------------------

  def check_query(question, answer, clue)
    q = Query.find(queries(:shoe_sko).id)
    assert_equal question, q.question
    assert_equal answer,   q.answer
    assert_equal clue,     q.clue
  end
  
  def lesson1
    Lesson.find lessons(:one).id
  end  
end
