class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authorize_from_github

  def authorize_from_github
    unless session[:token]
      redirect_to '/auth/github'
    end
  end

  def github
    @github ||= Octokit::Client.new :access_token => session[:token]
  end
  helper_method :github
end
