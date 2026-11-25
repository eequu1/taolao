class Phrase < ApplicationRecord
  belongs_to :visit
  delegate :user, to: :visit

  enum :source, { prepped: 0, heard: 1, manual: 2 }
  enum :status, { learning: 0, memorized: 1 }

  MEMORIZE_XP_PER_LEVEL = 5

  # Memorizing is in-app, so it only counts for phrases met in the real world:
  # ones the user said on a visit, or heard staff say.
  validate :met_in_real_life, if: :memorized?

  def memorizable?
    used? || heard?
  end

  # Returns the XP awarded: paid once per phrase, and once per Japanese text per user.
  def memorize!
    with_lock do
      first_time = memorized_at.nil? && !already_memorized_elsewhere?
      self.memorized_at ||= Time.current
      memorized!
      return 0 unless first_time

      xp = visit.place_level * MEMORIZE_XP_PER_LEVEL
      user.gain_experience!(xp)
      xp
    end
  end

  # Keeps memorized_at so memorizing again doesn't pay twice
  def unmemorize!
    learning!
  end

  private

  def met_in_real_life
    errors.add(:status, "can only be memorized after using or hearing the phrase on a visit") unless memorizable?
  end

  def already_memorized_elsewhere?
    Phrase.joins(:visit)
          .where(visits: { user_id: visit.user_id })
          .where(japanese: japanese)
          .where.not(id: id)
          .where.not(memorized_at: nil)
          .exists?
  end
end
