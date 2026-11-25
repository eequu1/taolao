class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :visits, dependent: :destroy
  # allow_nil: users loaded from the DB have no plain-text password, and must still be saveable
  validates :password, length: { minimum: 6 }, allow_nil: true

  MAX_LEVEL = 100
  # Going from level L to L+1 costs 25 * L XP, so a full-XP visit at a place
  # of your own level (10 * L) is ~2.5 visits per level at every stage.
  XP_STEP = 25

  # Total XP needed to reach a level: 25 * (1 + 2 + ... + (level - 1))
  def self.experience_for_level(level)
    XP_STEP * (level - 1) * level / 2
  end

  def self.level_for(experience)
    level = 1
    level += 1 while level < MAX_LEVEL && experience >= experience_for_level(level + 1)
    level
  end

  # Experience is only earned from real-world visits (see Visit and Phrase).
  # Returns how many levels were gained, for the level-up banner.
  def gain_experience!(amount)
    with_lock do
      previous_level = level
      self.experience += amount
      self.level = User.level_for(experience)
      save!
      level - previous_level
    end
  end

  def experience_into_level
    experience - User.experience_for_level(level)
  end

  # nil at max level: there is no next level to show progress towards
  def experience_for_next_level
    return nil if level >= MAX_LEVEL

    User.experience_for_level(level + 1) - User.experience_for_level(level)
  end
end
