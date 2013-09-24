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
        @team_days[team.id] = {}
        @marches[team.id] = {}
        team.team_members.each do |member|
          # github commits
          @events[member.id] = github(member.github_login).user(member.github_login).rels[:events].get.data
          @events[member.id] = @events[member.id]
                                 .select {|e| e.type == 'PushEvent' && e.created_at > Date.today.beginning_of_week}
                                 .collect {|e| {date: e.created_at.to_date.strftime('%a, %b %e %Y'),
                                                commits: e.payload.commits.select(&:distinct)
                                                           .collect {|c| {repo: e.repo.name.split('/').last, message: c.message}}
                                               }
                                 }
                                 .group_by {|e| e[:date]}

          # rescue time results for software dev
          begin
            if member.rescue_time_token.present?
              json = JSON.parse(RestClient.get("https://www.rescuetime.com/anapi/data?format=json&key=#{member.rescue_time_token}&perspective=interval&resolution_time=day&restrict_kind=category&restrict_thing=General%20Software%20Development"))
              if json['rows']
                @marches[team.id][member.id] = {}
                Date.today.beginning_of_week(:sunday).step(Date.today.end_of_week(:sunday)) do |day|
                  next if day > Date.today
                  @team_days[team.id][day] ||= 0
                  coding = 0.0
                  json['rows'].each do |row|
                    if Date.parse(row[0]) == day &&
                      ["General Software Development", "Systems Operations", "Data Modeling & Analysis", "Quality Assurance", "Project Management", "Editing & IDEs"].include?(row[3])
                      coding += row[1]
                    end
                  end
                  if coding > 0
                    amount = ((coding / 3600) * 10).to_i / 10.0
                    @marches[team.id][member.id][day] = amount
                    @team_days[team.id][day] += amount
                  end
                end
              end
            end
          #rescue
            # Unable to pull data for this person from rescue time
          end
        end

        @team_days[team.id][:cumulative] = 0
        days = 0
        Date.today.beginning_of_week(:sunday).step(Date.today.end_of_week(:sunday)) do |day|
          amount = (@team_days[team.id][day] || 0)
          if amount > 0
            days += 1
            amount = amount / @marches[team.id].select {|member, days| days[day].to_f > 0}.length
          else
           next
          end
          @team_days[team.id][:cumulative] += amount
        end
        @team_days[team.id][:cumulative] /= days
      end

      Rails.cache.write('team_days', @team_days, expires_in: 5.minutes)
      Rails.cache.write('marches', @marches, expires_in: 5.minutes)
      Rails.cache.write('events', @events, expires_in: 5.minutes)
    end
  end
end
