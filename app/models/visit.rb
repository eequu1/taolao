class Visit < ApplicationRecord
  belongs_to :user
  belongs_to :place
  has_many :phrases
  has_many :messages
  enum :status, { active: 0, ready: 1, completed: 2 }

  VISIT_XP_PER_LEVEL = 10
  PHRASE_XP_PER_LEVEL = 2
  MAX_REWARDED_PHRASES = 5 # so ticking every box doesn't inflate XP

  # Only checked when the user submits the post-visit review
  validates :self_rating, :confidence, inclusion: { in: 1..5 }, on: :review

  def reviewed?
    experience_awarded.present?
  end

  # Going out always pays; a rough or shaky visit pays less (never below 40%).
  def visit_experience
    base = place_level * VISIT_XP_PER_LEVEL
    outcome = 0.5 + ((self_rating - 1) * 0.125) # 1 -> 0.5x ... 5 -> 1.0x
    confidence_factor = 0.8 + ((confidence - 1) * 0.05) # 1 -> 0.8x ... 5 -> 1.0x
    [(base * outcome * confidence_factor).round, 1].max
  end

  def phrase_experience(used_count)
    [used_count, MAX_REWARDED_PHRASES].min * place_level * PHRASE_XP_PER_LEVEL
  end

  # Saves the review, marks used phrases and awards XP, all or nothing.
  # Returns levels gained (0 if this visit was already reviewed).
  def complete_review!(self_rating:, confidence:, used_phrase_ids: [])
    with_lock do
      return 0 if reviewed?

      self.self_rating = self_rating
      self.confidence = confidence
      validate!(:review) # check ratings before touching phrases

      self.experience_awarded = visit_experience + phrase_experience(mark_phrases_used(used_phrase_ids))
      self.status = :completed
      save!(context: :review)
      user.gain_experience!(experience_awarded)
    end
  end

  def place_level
    place.minimum_level || 1
  end

  private

  # Only this visit's prepped phrases count; returns how many were marked
  def mark_phrases_used(ids)
    phrases.prepped.where(id: ids).update_all(used: true)
  end
end
