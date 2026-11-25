class AddExperienceToUsers < ActiveRecord::Migration[8.1]
  def change
    # Total XP ever earned; level is calculated from this
    add_column :users, :experience, :integer, default: 0, null: false

    # New users start at level 1; the 4th argument backfills existing NULL levels with 1
    change_column_default :users, :level, from: nil, to: 1
    change_column_null :users, :level, false, 1
  end
end
