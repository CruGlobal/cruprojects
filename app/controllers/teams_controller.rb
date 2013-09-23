class TeamsController < ApplicationController
  def index
    @teams = Team.all
    @events = {}
    @marches = {}
    @team_days = {}

    @teams.each do |team|
      @team_days[team] = {}
      @marches[team] = {}
      team.team_members.each do |member|
        # github commits
        @events[member] = github(member.github_login).user(member.github_login).rels[:events].get.data
        @events[member] = @events[member].select {|e| e.type == 'PushEvent' && e.created_at > Date.today.beginning_of_week}.group_by {|e| e.created_at.to_date}

        # rescue time results for software dev
        begin
          if member.rescue_time_token.present?
            json = JSON.parse(RestClient.get("https://www.rescuetime.com/anapi/data?format=json&key=#{member.rescue_time_token}&perspective=interval&resolution_time=day&restrict_kind=category&restrict_thing=General%20Software%20Development"))
            if json['rows']
              @marches[team][member] = {}
              Date.today.beginning_of_week(:sunday).step(Date.today.end_of_week(:sunday)) do |day|
                next if day > Date.today
                @team_days[team][day] ||= 0
                coding = 0.0
                json['rows'].each do |row|
                  if Date.parse(row[0]) == day &&
                    ["General Software Development", "Systems Operations", "Data Modeling & Analysis", "Quality Assurance", "Project Management", "Editing & IDEs"].include?(row[3])
                    coding += row[1]
                  end
                end
                if coding > 0
                  amount = ((coding / 3600) * 10).to_i / 10.0
                  @marches[team][member][day] = amount
                  @team_days[team][day] += amount
                end
              end
            end
          end
        rescue
          # Unable to pull data for this person from rescue time
        end
      end
    end
  end
end
