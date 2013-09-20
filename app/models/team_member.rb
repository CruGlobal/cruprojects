class TeamMember < ActiveRecord::Base
  belongs_to :team

  validates :team_id, presence: true
end
