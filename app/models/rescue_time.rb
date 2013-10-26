class RescueTime

  def initialize(team_member)
    @team_member = team_member
  end

  def data(start_date, end_date)
    json = JSON.parse(RestClient.get("https://www.rescuetime.com/anapi/data?format=json&key=#{@team_member.rescue_time_token}&perspective=interval&resolution_time=day&restrict_kind=category&restrict_begin=#{start_date.to_s(:db)}&restrict_end=#{end_date.to_s(:db)}"))
    json['rows'] || []
  end

end
