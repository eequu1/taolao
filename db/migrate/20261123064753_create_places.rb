class CreatePlaces < ActiveRecord::Migration[8.1]
  def change
    create_table :places do |t|
      t.string :name
      t.text :description
      t.float :lat
      t.float :long
      t.integer :minimum_level

      t.timestamps
    end
  end
end
