# Starter phrases shared by everyone who looks at a place: an AI-generated, start-to-finish
# ordering conversation. Separate from `phrases`, which belong to a user's visit (XP, study list).
class CreatePlacePhrases < ActiveRecord::Migration[8.1]
  def change
    create_table :place_phrases do |t|
      t.references :place, null: false, foreign_key: true
      t.integer :position, null: false # order in the conversation
      t.integer :stage, null: false    # arriving / ordering / details / paying / leaving
      t.integer :speaker, null: false, default: 0 # customer / staff
      t.string :japanese, null: false
      t.string :romaji, null: false
      t.string :english, null: false
      t.timestamps
    end
    add_index :place_phrases, %i[place_id position], unique: true

    # Set while a PlacePhrasesJob is running, so a second visitor doesn't start another
    add_column :places, :phrases_generating_since, :datetime
  end
end
