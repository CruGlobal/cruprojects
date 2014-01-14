class ReposController < ApplicationController
  def index
    github.auto_paginate = true
    @orgs = {'AgapeEurope' => [],'CruGlobal' => [], 'PowerToChange' => []}
    @orgs.keys.each do |org_name|
      res = github.paginate(github.org(org_name).rels[:repos].href)
      @orgs[org_name] = res.sort_by(&:name)
    end
  end

  def details
    @repo_name = params[:name]
    @repo = github.repo(@repo_name)
    @collaborators = @repo.rels[:contributors].get.data.sort_by(&:login)
    @commits = @repo.rels[:commits].get.data
  end
end
