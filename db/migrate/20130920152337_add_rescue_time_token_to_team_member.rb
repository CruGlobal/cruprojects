class AddRescueTimeTokenToTeamMember < ActiveRecord::Migration
  def change
    add_column :team_members, :rescue_time_token, :string
  end
end
