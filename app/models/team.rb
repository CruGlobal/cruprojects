class Team < ActiveRecord::Base
  has_many :team_members, inverse_of: :team

  def load_data(events, marches, team_days, current_token, start_date, end_date)

    team_days[id] = {}
    marches[id] = {}
    team_members.each do |member|
      member.load_data(events, marches, team_days, current_token, start_date, end_date)
    end
    team_days[id][:cumulative] = 0
    days = 0
    start_date.step(end_date) do |day|
      amount = (team_days[id][day] || 0)
      if amount > 0
        days += 1
        amount = amount / marches[id].select {|member, ds| ds[day].to_f > 0}.length
      else
        next
      end
      team_days[id][:cumulative] += amount
    end
    team_days[id][:cumulative] /= days if days > 0
  end
end
