class Message < ApplicationRecord
  belongs_to :visit

  # prep = "Prepare with AI" before the visit; review = post-visit phrase finder.
  # Each chat only sends its own messages to the AI.
  enum :purpose, { prep: 0, review: 1 }

  ROLES = %w[user assistant].freeze
  MAX_LENGTH = 2000
  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true, length: { maximum: MAX_LENGTH }
end
