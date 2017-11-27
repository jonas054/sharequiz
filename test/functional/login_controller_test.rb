# -*- coding: utf-8 -*-
require 'test_helper'

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < ActionController::TestCase
  def test_index_without_user
    get :index
    assert_redirected_to :controller => 'login', :action => 'login'
  end

  def test_index_with_user
    get :index, {}, { :user_id => users(:jonas).id }
    assert_response :success
    assert_template 'index'
  end

  def test_login
    jonas = users(:jonas)
    post :login, :name => jonas.name, :password => 'secret'
    assert_redirected_to :controller => 'lessons'
    assert_equal jonas.id, session[:user_id]
  end

  def test_bad_password
    post :login, :name => users(:jonas).name, :password => 'wrong'
    assert_template 'login'
    assert_equal 'Invalid user/password combination', flash[:notice]
  end

  def test_help
    get :help
    assert_response :success
    assert_template 'help.'

    get :help, {}, :display_language => 'Swedish'
    assert_response :success
    assert_template 'help_sv'
  end

  def test_preferences
    jonas_id = users(:jonas).id

    get :preferences, {}, :user_id => jonas_id
    assert_response :success
    assert_template 'preferences'
    assert_equal jonas_id, assigns(:user).id
    assert_equal 'Settings - ShareQuiz', assigns(:page_title)

    get(:preferences, {},
        :user_id => jonas_id, :display_language => 'Swedish')
    assert_equal 'Inställningar - ShareQuiz', assigns(:page_title)

    get :preferences, {}, :user_id => nil # No current user
    assert_redirected_to :controller => 'login', :action => 'login'
  end

  def test_new_preferences
    jonas_id = users(:jonas).id
    post(:new_preferences,
         {
           :user_id => jonas_id,
           :user => {
             :display_language => 'Swedish',
             :quiz_length => 7,
             :goal => 14,
             :native_language => languages(:chi).id
           }
         },
         :user_id => jonas_id)
    assert_redirected_to :controller => 'lessons'
    user = User.find jonas_id
    assert_equal 'Swedish', session[:display_language]
    assert_equal 'Swedish', user.display_language
    assert_equal 7, user.quiz_length
    assert_equal 14, user.goal
    assert_equal languages(:chi).id, user.native_language
  end
  
  def test_new_preferences_not_logged_in
    jonas_id = users(:jonas).id
    post(:new_preferences,
         {
           :user_id => jonas_id,
           :user => { :goal => 14 }
         })
    assert_redirected_to :controller => 'login', :action => 'login'
    user = User.find jonas_id
    assert_equal 10, user.goal
  end
  
  def test_create_new_account
    post(:add_user,
         :user => {
           :name                  => 'newguy',
           :password              => 'penguin',
           :password_confirmation => 'penguin'
         })
    assert_redirected_to :controller => 'lessons', :action => 'index'
    assert_equal 'newguy', User.find(session[:user_id]).name
  end
  
  def test_logout
    get :logout, {}, { :user_id => users(:jonas).id }
    assert_redirected_to :controller => 'lessons'
    assert_equal nil, session[:user_id]
  end
end
