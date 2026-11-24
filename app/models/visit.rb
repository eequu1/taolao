class Visit < ApplicationRecord
  belongs_to :user
  belongs_to :place
  has_many :phrases
  has_many :messages
  enum :status, { active: 0, ready: 1, completed: 2 }
end
