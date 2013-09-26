class TeamMember < ActiveRecord::Base
  belongs_to :team#, inverse_of: :team_members

  validates :team_id, presence: true

  def load_data(events, marches, team_days, current_token)
    # github commits
    events[id] = github(current_token).user(github_login).rels[:events].get.data
    events[id] = events[id]
                           .select {|e| e.type == 'PushEvent' && e.created_at > Date.today.beginning_of_week}
                           .collect {|e| {date: e.created_at.to_date.strftime('%a, %b %e %Y'),
                                          commits: e.payload.commits.select(&:distinct)
                                                     .collect {|c| {repo: e.repo.name.split('/').last, message: c.message}}
                                         }
                           }
                           .group_by {|e| e[:date]}

    # rescue time results for software dev
    begin
      if rescue_time_token.present?
        json = JSON.parse(RestClient.get("https://www.rescuetime.com/anapi/data?format=json&key=#{rescue_time_token}&perspective=interval&resolution_time=day&restrict_kind=category&restrict_thing=General%20Software%20Development"))
        if json['rows']
          marches[team.id][id] = {}
          Date.today.beginning_of_week(:sunday).step(Date.today.end_of_week(:sunday)) do |day|
            next if day > Date.today
            team_days[team.id][day] ||= 0
            coding = 0.0
            json['rows'].each do |row|
              if Date.parse(row[0]) == day &&
                ["General Software Development", "Systems Operations", "Data Modeling & Analysis", "Quality Assurance", "Project Management", "Editing & IDEs", "Design & Planning"].include?(row[3])
                coding += row[1]
              end
            end
            amount = ((coding / 3600) * 10).to_i / 10.0
            if amount > 0.2
              marches[team.id][id][day] = amount
              team_days[team.id][day] += amount
            end
          end
        end
      end
    rescue
      # Unable to pull data for this person from rescue time
    end
  end

  def github(current_token)
    token = access_token || current_token

    Octokit::Client.new :access_token => token
  end
end
