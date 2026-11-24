class AddLevelToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :level, :integer
  end
end
