class TeamsController < ApplicationController
  def index
    @events = github.user('twinge').rels[:events].get.data
    @events = @events.select! {|e| e.type == 'PushEvent' && e.created_at > Date.today.beginning_of_week}.group_by {|e| e.created_at.to_date}
  end
end
