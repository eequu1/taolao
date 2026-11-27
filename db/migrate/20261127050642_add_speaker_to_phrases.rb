# Who says a phrase (customer / staff), as on PlacePhrase. Heard phrases are what staff said.
class AddSpeakerToPhrases < ActiveRecord::Migration[8.1]
  def up
    add_column :phrases, :speaker, :integer, default: 0, null: false
    execute "UPDATE phrases SET speaker = 1 WHERE source = 1" # source heard -> speaker staff
  end

  def down
    remove_column :phrases, :speaker
  end
end
