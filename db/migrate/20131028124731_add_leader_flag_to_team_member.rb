class AddLeaderFlagToTeamMember < ActiveRecord::Migration
  def change
    add_column :team_members, :leader, :boolean, default: false, null: false
  end
end
