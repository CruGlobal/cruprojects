class TeamMember < ActiveRecord::Base
  belongs_to :team#, inverse_of: :team_members
  has_many :github_commits
  has_many :rescue_time_category_days

  validates :team_id, presence: true

  SOFTWARE_DEV = ["General Software Development", "Systems Operations", "Data Modeling & Analysis", "Quality Assurance", "Project Management", "Editing & IDEs", "Design & Planning"]

  def load_data(events, marches, team_days, current_token)
    # github commits
    data = github(current_token).user(github_login).rels[:events].get.data
    data.select {|e| e.type == 'PushEvent' && e.created_at > Date.today.beginning_of_week}
        .map {|e|  e.payload.commits.select(&:distinct)
                                    .map {|c| github_commits.where(sha: c.sha, repo: e.repo.name)
                                                            .first_or_create(commit_message: c.message, push_date: e.created_at)
                                         }

             }

    events[id] = github_commits.where("push_date >= ?", Date.today.beginning_of_week).collect {|c| {date: c.push_date, repo: c.repo, message: c.commit_message, sha: c.sha}}

    # rescue time results for software dev
    begin
      if rescue_time_token.present?
        marches[team.id][id] = {}
        Date.today.beginning_of_week(:sunday).step(Date.today.end_of_week(:sunday)) do |day|
          break if day > Date.today
          team_days[team.id][day] ||= 0
          coding = 0.0
          if day == Date.today || day == Date.yesterday
            json = JSON.parse(RestClient.get("https://www.rescuetime.com/anapi/data?format=json&key=#{rescue_time_token}&perspective=interval&resolution_time=day&restrict_kind=category&restrict_begin=#{day.to_s(:db)}"))
            # use the data from the API
            if json['rows']
              json['rows'].each do |row|
                rescue_day = Date.parse(row[0])
                if rescue_day == day
                  day_cat = rescue_time_category_days.where(day: day, category: row[3]).first_or_create
                  day_cat.update(amount: row[1])
                  if SOFTWARE_DEV.include?(row[3])
                    coding += row[1]
                  end
                end
              end
            end
          else
            # use the data in the db
            coding += rescue_time_category_days.where(day: day, category: SOFTWARE_DEV).sum(:amount)
          end

          amount = ((coding / 3600) * 10).to_i / 10.0
          if amount > 0.2
            marches[team.id][id][day] = amount
            team_days[team.id][day] += amount
          end
        end
      end
    #rescue
      # Unable to pull data for this person from rescue time
    end
  end

  def github(current_token)
    token = access_token || current_token

    Octokit::Client.new :access_token => token
  end
end
