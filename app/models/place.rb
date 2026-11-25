class Place < ApplicationRecord
  has_many :visits, dependent: :destroy
  has_many :phrases, through: :visits

  geocoded_by :name, latitude: :lat, longitude: :long
end
