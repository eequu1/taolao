class Place < ApplicationRecord
  has_many :visits, dependent: :destroy

  geocoded_by :name, latitude: :lat, longitude: :long
end
