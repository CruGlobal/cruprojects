class ReposController < ApplicationController
  def index
    @orgs = ['AgapeEurope','CruGlobal']
  end

  def details
    @repo_name = params[:name]
    @repo = github.repo(@repo_name)
    @collaborators = @repo.rels[:contributors].get.data.sort_by(&:login)
    @commits = @repo.rels[:commits].get.data
  end
end
