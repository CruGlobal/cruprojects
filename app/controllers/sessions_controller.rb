class SessionsController < ApplicationController
  skip_before_filter :authorize_from_github

  def create
    session[:user] = auth_hash.info.nickname
    session[:token]= auth_hash.credentials.token
    if team_member = TeamMember.find_by(github_login: session[:user])
      team_member.update_attributes(access_token: session[:token])
    end

    redirect_to(session[:return_to] || '/')
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
