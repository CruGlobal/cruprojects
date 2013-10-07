class TeamsController < ApplicationController
  def index
    @teams = Team.all
    @events = Rails.cache.fetch(['events', params[:start_date]])
    @marches = Rails.cache.fetch(['marches', params[:start_date]])
    @team_days = Rails.cache.fetch(['team_days', params[:start_date]])

    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week(:sunday)
    @end_date = @start_date + 6.days

    unless @events && @marches && @team_days
      @events = {}
      @marches = {}
      @team_days = {}

      @teams.each do |team|
        team.load_data(@events, @marches, @team_days, session[:token], @start_date, @end_date)
      end

      Rails.cache.write(['team_days', params[:start_date]], @team_days, expires_in: 5.minutes)
      Rails.cache.write(['marches', params[:start_date]], @marches, expires_in: 5.minutes)
      Rails.cache.write(['events', params[:start_date]], @events, expires_in: 5.minutes)
    end
  end
end
