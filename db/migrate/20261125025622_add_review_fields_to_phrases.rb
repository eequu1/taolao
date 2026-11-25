class AddReviewFieldsToPhrases < ActiveRecord::Migration[8.1]
  def change
    # Ticked on the review screen when the user actually said this phrase
    add_column :phrases, :used, :boolean, default: false, null: false
    # Where the phrase came from: 0 = prepped, 1 = heard (AI suggestion), 2 = manual
    add_column :phrases, :source, :integer, default: 0, null: false
    # 0 = learning, 1 = memorized
    add_column :phrases, :status, :integer, default: 0, null: false
    # Set the first time it's memorized and never cleared, so the bonus pays once
    add_column :phrases, :memorized_at, :datetime
  end
end
