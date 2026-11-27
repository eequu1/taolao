class AddTranslationToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :translation, :text
  end
end
