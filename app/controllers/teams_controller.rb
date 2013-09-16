class TeamsController < ApplicationController
  def index
    @team = Team.first
    @events = {}
    @team.team_members.each do |member|
      @events[member.github_login] = github.user(member.github_login).rels[:events].get.data
      @events[member.github_login] = @events[member.github_login].select {|e| e.type == 'PushEvent' && e.created_at > Date.today.beginning_of_week}.group_by {|e| e.created_at.to_date}
    end
  end
end
