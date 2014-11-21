class TeamMember < ActiveRecord::Base
  belongs_to :team#, inverse_of: :team_members
  has_many :github_commits
  has_many :rescue_time_category_days
  has_many :off_days

  validates :team_id, presence: true

  SOFTWARE_DEV = ['General Software Development', 'Systems Operations', 'Data Modeling & Analysis', 'Quality Assurance',
                  'Project Management', 'Editing & IDEs', 'Design & Planning', 'Troubleshooting', 'General Utilities',
                  'Virtualization']

  WORK_CATS = ['General Business', 'Email', 'Meetings', 'Instant Message', 'Voice Chat', 'Writing',
               'General Communication & Scheduling', 'General Reference & Learning', 'Engineering & Technology',
               'Calendars', 'Administration', 'Operations', 'Gmail', 'Meeting (offline)', 'Customer Relations',
               'General Design & Composition', 'Research', 'Writing']

  def load_data(events = {}, marches = {}, work = {}, team_days = {}, current_token = access_token, start_date, end_date)
    unless events[id]
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
    end
    # rescue time results for software dev
    begin
      if rescue_time_token.present?
        marches[team_id] ||= {}
        marches[team_id][id] = {}
        work[team_id] ||= {}
        work[team_id][id] = {}
        rows = RescueTime.new(self).data(start_date, end_date).group_by {|r| Date.parse(r[0]) }

        start_date.step(end_date) do |day|
          break if day > Date.today
          # If this is saturday or sunday, count the time towards monday
          acting_day = case
                       when day.saturday?
                         day - 1.day
                       when day.sunday?
                         day + 1.day
                       else
                         day
                       end

          off_day = off_days.find_by(off_day: acting_day)

          coding = 0.0
          work_time = 0.0
          # if acting_day >= Date.yesterday
            # use the data from the API
            if rows && rows[day]
              rows[day].group_by {|r| r[3]}.each do |category, cat_rows|
                cat_total = cat_rows.sum {|r| r[1]}
                day_cat = rescue_time_category_days.where(day: day, category: category).first_or_create
                day_cat.update(amount: cat_total)
                case
                when SOFTWARE_DEV.include?(category)
                  coding += cat_total
                when WORK_CATS.include?(category)
                  work_time += cat_total
                end
              end
            end
          # else
            #use the data in the db
            # coding += rescue_time_category_days.where(day: day, category: SOFTWARE_DEV).sum(:amount)
            # work_time += rescue_time_category_days.where(day: day, category: WORK_CATS).sum(:amount)
          # end

          coding_amount = ((coding / 3600) * 10).to_i / 10.0
          work_amount = ((work_time / 3600) * 10).to_i / 10.0
          if work_amount + coding_amount > 0.2
            work[team_id][id][acting_day] ||= 0
            work[team_id][id][acting_day] += work_amount + coding_amount
            unless off_day
              marches[team_id][id][acting_day] ||= 0
              marches[team_id][id][acting_day] += coding_amount
              team_days[team_id] ||= {}
              team_days[team_id][acting_day] ||= 0
              team_days[team_id][acting_day] += coding_amount
            end
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
