class AddReviewFieldsToVisits < ActiveRecord::Migration[8.1]
  def change
    # "How confident did you feel?" 1–5 (self_rating already exists for "How did it go?")
    add_column :visits, :confidence, :integer
    # XP this review granted; if it's set, the visit was already rewarded
    add_column :visits, :experience_awarded, :integer
  end
end
