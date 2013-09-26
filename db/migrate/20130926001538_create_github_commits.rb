class CreateGithubCommits < ActiveRecord::Migration
  def change
    create_table :github_commits do |t|
      t.date :push_date
      t.belongs_to :team_member, index: true
      t.text :commit_message
      t.string :repo

      t.timestamps
    end
  end
end
