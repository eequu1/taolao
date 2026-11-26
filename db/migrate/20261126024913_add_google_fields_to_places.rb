class AddGoogleFieldsToPlaces < ActiveRecord::Migration[8.1]
  def change
    add_column :places, :google_place_id, :string
    add_column :places, :address, :string
  end
end
