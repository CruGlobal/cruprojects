class OffDaysController < ApplicationController
  after_filter :flush_cache

  def create
    tm = TeamMember.find(params[:team_member_id])
    @off_day = tm.off_days.create(reason: params[:reason], off_day: params[:off_day])

    redirect_to teams_path
  end

  def destroy
    @off_day = OffDay.find(params[:id])
    @off_day.destroy

    redirect_to teams_path
  end

  private

  def flush_cache
    cache_date = (@off_day.off_day.beginning_of_week(:sunday) == Date.today.beginning_of_week(:sunday)) ? nil : @off_day.off_day
    Rails.cache.write(['marches', cache_date], nil)
  end
end
