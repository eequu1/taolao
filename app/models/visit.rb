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

  # The review page's "Which phrases did you use?" list: this visit's phrases, then the
  # user's phrases from earlier visits here, then the place's starter phrases (PlacePhrase).
  # Each Japanese text appears once (exact match), the first one found winning.
  def review_phrase_choices
    candidates = phrases.order(:created_at).to_a +
                 earlier_phrases_here.order(:created_at).to_a +
                 place.place_phrases.to_a
    seen = Set.new
    candidates.select { |phrase| phrase.japanese.blank? || seen.add?(phrase.japanese) }
  end

  # Saves the review, marks used phrases and awards XP, all or nothing.
  # Returns levels gained (0 if this visit was already reviewed).
  def complete_review!(self_rating:, confidence:, used_phrase_ids: [], used_place_phrase_ids: [])
    with_lock do
      return 0 if reviewed?

      assign_attributes(self_rating: self_rating, confidence: confidence)
      validate!(:review) # check ratings before touching phrases

      used_count = mark_phrases_used(used_phrase_ids, used_place_phrase_ids)
      self.experience_awarded = visit_experience + phrase_experience(used_count)
      self.status = :completed
      save!(context: :review)
      user.gain_experience!(experience_awarded)
    end
  end

  def place_level
    place.minimum_level || 1
  end

  private

  # The user's phrases from their other visits to this place
  def earlier_phrases_here
    Phrase.for_user_at(user, place).where.not(visit_id: id)
  end

  # Ticked phrases from this visit are marked used. Ones from the user's earlier visits
  # here or from the place's starter list are copied onto this visit first; anything
  # else (other places, other users) is ignored. Returns how many were marked.
  def mark_phrases_used(phrase_ids, place_phrase_ids)
    sources = earlier_phrases_here.where(id: phrase_ids).to_a + place.place_phrases.where(id: place_phrase_ids).to_a
    ids = phrase_ids + sources.map { |source| copy_phrase(source).id }
    phrases.where(id: ids).update_all(used: true)
  end

  # Reuses this visit's phrase with the same Japanese (exact match) if there is one
  def copy_phrase(source)
    attrs = { romaji: source.romaji, english: source.english, speaker: source.speaker, source: :prepped }
    return phrases.create!(japanese: source.japanese, **attrs) if source.japanese.blank?

    phrases.create_with(attrs).find_or_create_by!(japanese: source.japanese)
  end
end
