class AddCategoryToPlaces < ActiveRecord::Migration[8.1]
  def change
    add_column :places, :category, :string
  end
end
