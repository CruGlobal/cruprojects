class CreateTeamMembers < ActiveRecord::Migration
  def change
    create_table :team_members do |t|
      t.string :name
      t.string :github_login
      t.string :access_token
      t.integer :team_id

      t.timestamps
    end

    add_index :team_members, :team_id
  end
end
