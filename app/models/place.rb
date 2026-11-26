class Place < ApplicationRecord
  has_many :visits, dependent: :destroy
  has_many :phrases, through: :visits

  geocoded_by :name, latitude: :lat, longitude: :long
  reverse_geocoded_by :lat, :long
end
