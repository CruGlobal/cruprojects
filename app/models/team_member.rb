class TeamMember < ActiveRecord::Base
  belongs_to :team#, inverse_of: :team_members
  has_many :github_commits
  has_many :rescue_time_category_days

  validates :team_id, presence: true

  SOFTWARE_DEV = ['General Software Development', 'Systems Operations', 'Data Modeling & Analysis', 'Quality Assurance', 'Project Management', 'Editing & IDEs', 'Design & Planning', 'Troubleshooting']

  def load_data(events, marches, team_days, current_token, start_date, end_date)
    # github commits
    begin
      data = github(current_token).user(github_login).rels[:events].get.data
      data.select {|e| e.type == 'PushEvent' && e.created_at > start_date}
          .map {|e|  e.payload.commits.select(&:distinct)
                                      .map {|c| github_commits.where(sha: c.sha, repo: e.repo.name)
                                                              .first_or_create(commit_message: c.message, push_date: e.created_at)
                                           }

               }
    rescue
      # Don't puke just because github is down
    end
    events[id] = github_commits.where("push_date >= ?", start_date).collect {|c| {date: c.push_date, repo: c.repo, message: c.commit_message, sha: c.sha}}

    # rescue time results for software dev
    begin
      if rescue_time_token.present?
        marches[team.id][id] = {}
        json = JSON.parse(RestClient.get("https://www.rescuetime.com/anapi/data?format=json&key=#{rescue_time_token}&perspective=interval&resolution_time=day&restrict_kind=category&restrict_begin=#{start_date.to_s(:db)}"))
        rows = json['rows'].group_by {|r| Date.parse(r[0]) } if json['rows']

        start_date.step(end_date) do |day|
          break if day > Date.today
          team_days[team.id][day] ||= 0
          coding = 0.0
          if day == Date.today || day == Date.yesterday
            # use the data from the API
            if rows && rows[day]
              rows[day].group_by {|r| r[4]}.each do |category, cat_rows|
                cat_total = cat_rows.sum {|r| r[1]}
                day_cat = rescue_time_category_days.where(day: day, category: category).first_or_create
                day_cat.update(amount: cat_total)
                if SOFTWARE_DEV.include?(category)
                  coding += cat_total
                end
              end
            end
          else
             #use the data in the db
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
