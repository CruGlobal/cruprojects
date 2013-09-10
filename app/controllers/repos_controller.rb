class ReposController < ApplicationController
  def index
    @orgs = ['AgapeEurope','CruGlobal']
  end

  def show
    @repo_name = CGI::unescape(params[:id])
    @repo = github.repo(@repo_name)
    @collaborators = @repo.rels[:contributors].get.data.sort_by(&:login)
    @commits = @repo.rels[:commits].get.data
  end
end
