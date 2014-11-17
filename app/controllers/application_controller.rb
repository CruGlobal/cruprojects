class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :authorize_from_github

  def authorize_from_github
    if session[:token]
      # make sure the token is stored
      if team_member = TeamMember.find_by(github_login: session[:user])
        team_member.update_attributes(access_token: session[:token])
      end
    else
      session[:return_to] = request.path
      redirect_to '/auth/github'
    end
  end

  def github(user = nil)
    @githubs ||= {}
    key = user || 'default'
    unless @githubs[key]
      user ||= session[:user]
      if team_member = TeamMember.find_by(github_login: user)
        token = team_member.access_token
      end

      token ||= session[:token]

      @githubs[key] = Octokit::Client.new :access_token => token
    end

    @githubs[key]
  end
  helper_method :github

  def current_user
    @current_user ||= (TeamMember.find_by(github_login: session[:user]) || TeamMember.new)
  end
  helper_method :current_user
end
