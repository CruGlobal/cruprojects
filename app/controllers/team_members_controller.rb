class TeamMembersController < ApplicationController
  before_filter :get_team_member

  def rescue
    @date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today

    if current_user.leader?
      @rows = RescueTime.new(@team_member).data(@date, @date)
    end
  end

  def index
    @teams = Team.all

    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_year
    @end_date = Date.yesterday


    expiration_time = 1.day
    
    @off_days = Rails.cache.fetch(['off_days', @start_date], expires_in: expiration_time) do
      counts = {}
      TeamMember.all.each do |tm|
        counts[tm.id] = tm.off_days.group(:reason).count
      end
      counts
    end
    
    @member_summary = Rails.cache.fetch(['member_summary', @start_date])
    @commit_summary = Rails.cache.fetch(['commit_summary', @start_date], expires_in: expiration_time) do
      GithubCommit.group(:team_member_id).order("count(*) desc").count
    end

    unless @member_summary
      @events = {}
      @marches = {}
      @team_days = {}

      token = TeamMember.where("access_token is not null").first.access_token

      @teams.each do |team|
        team.load_data(@events, @marches, @team_days, token, @start_date, @end_date)
      end

      @member_marches = {}
      Team.all.each do |team|
        @member_marches.merge!(@marches[team.id])
      end

      @member_summary = {}
      @member_marches.each do |id, marches|
        @member_summary[id] = marches.sum { |date, amount| amount } / marches.keys.length
      end

      Rails.cache.write(['member_summary', @start_date], @member_summary, expires_in: expiration_time)
    end

    @member_summary = Hash[@member_summary.sort_by { |id, amount| amount }.reverse]
  end

  private

  def get_team_member
    @team_member = TeamMember.find(params[:id]) if params[:id]
  end
end
