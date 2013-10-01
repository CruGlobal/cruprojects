class TeamsController < ApplicationController
  def index
    @teams = Team.all
    @events = Rails.cache.fetch('events')
    @marches = Rails.cache.fetch('marches')
    @team_days = Rails.cache.fetch('team_days')

    unless @events && @marches && @team_days
      @events = {}
      @marches = {}
      @team_days = {}

      @teams.each do |team|
        team.load_data(@events, @marches, @team_days, session[:token])
      end

      Rails.cache.write('team_days', @team_days, expires_in: 5.minutes)
      Rails.cache.write('marches', @marches, expires_in: 5.minutes)
      Rails.cache.write('events', @events, expires_in: 5.minutes)
    end
  end
end
