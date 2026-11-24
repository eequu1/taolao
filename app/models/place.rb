class Place < ApplicationRecord
  has_many :visits, dependent: :destroy
  has_many :phrases, through: :visits
end
