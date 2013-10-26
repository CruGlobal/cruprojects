class CreateOffDays < ActiveRecord::Migration
  def change
    create_table :off_days do |t|
      t.date :off_day
      t.belongs_to :team_member, index: true
      t.string :reason

      t.timestamps
    end
  end
end
