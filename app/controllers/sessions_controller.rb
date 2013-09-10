class SessionsController < ApplicationController
  skip_before_filter :authorize_from_github

  def create
    session[:user] = auth_hash.info.nickname.inspect
    session[:token]= auth_hash.credentials.token
    redirect_to '/'
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
