class TeamMembersController < ApplicationController
  before_filter :get_team_member

  def rescue
    @date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today

    @rows = RescueTime.new(@team_member).data(@date, @date)
  end

  private

  def get_team_member
    @team_member = TeamMember.find(params[:id])
  end
end
