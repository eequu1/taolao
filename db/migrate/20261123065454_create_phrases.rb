class CreatePhrases < ActiveRecord::Migration[8.1]
  def change
    create_table :phrases do |t|
      t.string :english
      t.string :japanese
      t.string :romaji
      t.references :visit, null: false, foreign_key: true

      t.timestamps
    end
  end
end
