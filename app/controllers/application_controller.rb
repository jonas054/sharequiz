# -*- coding: utf-8 -*-
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include Translation

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '06285af6bc4f8f40bc15a9f21edc41ab'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data
  # parameters from your application log (in this case, all fields
  # with names like "password").
  # filter_parameter_logging :password

  private

  def authorize
    unless User.find_by_id session[:user_id]
      redirect_to :controller => "login", :action => "login"
    end
  end
end
