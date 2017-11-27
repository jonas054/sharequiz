class LoginController < ApplicationController
  before_filter :authorize, :except => [:login, :add_user, :help]

  layout "admin"

  def help
    @page_title = text(:help) + ' - ShareQuiz'
    render :action => 'help_sv' if session[:display_language] == 'Swedish'
  end
  
  # Just display the form and wait for user to enter a name and password.
  def login
    session[:user_id] = nil
    if request.post?
      user = User.authenticate params[:name], params[:password]
      if user
        session[:user_id] = user.id
        session[:display_language] = user.display_language
        redirect_to :controller => 'lessons'
      else
        flash[:notice] = "Invalid user/password combination"
      end
    end
    @page_title = text(:log_in) + ' - ShareQuiz'
  end

  def add_user
    @user = User.new params[:user]
    if request.post? and @user.save
      session[:user_id] = @user.id
      redirect_to :controller => "lessons", :action => "index"
    end
  end

  def preferences
    @user = User.find session[:user_id]
    @page_title = text(:tools) + ' - ShareQuiz'
  end
  
  def new_preferences
    user = User.find session[:user_id]
    if user.update_attributes params[:user]
      session[:display_language] = params[:user][:display_language]
      redirect_to :controller => 'lessons'
    else
      flash[:error] = user.errors.full_messages.first
      redirect_to :action => 'preferences'
    end
  end
  
  def logout
    session[:user_id] = nil
    redirect_to :controller => 'lessons'
  end
end
