class TeamsController < ApplicationController
  def index
    @teams = Team.all

    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week(:sunday)

    params[:start_date] = nil if @start_date == Date.today.beginning_of_week(:sunday)

    @events = Rails.cache.fetch(['events', params[:start_date]])
    @marches = Rails.cache.fetch(['marches', params[:start_date]])
    @work = Rails.cache.fetch(['work', params[:start_date]])
    @team_days = Rails.cache.fetch(['team_days', params[:start_date]])

    @end_date = @start_date + 6.days

    unless @events && @marches && @team_days && @work
      @events ||= {}
      @marches ||= {}
      @work ||= {}
      @team_days ||= {}

      @teams.each do |team|
        team.load_data(@events, @marches, @work, @team_days, session[:token], @start_date, @end_date)
      end

      expiration_time = @start_date < Date.today.beginning_of_week(:sunday) ? 1.day : 10.minutes
      Rails.cache.write(['team_days', params[:start_date]], @team_days, expires_in: expiration_time)
      Rails.cache.write(['marches', params[:start_date]], @marches, expires_in: expiration_time)
      Rails.cache.write(['work', params[:start_date]], @work, expires_in: expiration_time)
      Rails.cache.write(['events', params[:start_date]], @events, expires_in: expiration_time)
    end
  end
end
