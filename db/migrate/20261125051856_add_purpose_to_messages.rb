class AddPurposeToMessages < ActiveRecord::Migration[8.1]
  def change
    # Keeps chats on the same visit apart: 0 = prep ("Prepare with AI"), 1 = review (post-visit phrase finder)
    add_column :messages, :purpose, :integer, default: 0, null: false
  end
end
