class CreateRescueTimeCategoryDays < ActiveRecord::Migration
  def change
    create_table :rescue_time_category_days do |t|
      t.date :day
      t.string :category
      t.integer :amount, default: 0
      t.belongs_to :team_member, index: true

      t.timestamps
    end
  end
end
