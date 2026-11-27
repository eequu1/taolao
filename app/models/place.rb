class Place < ApplicationRecord
  has_many :visits, dependent: :destroy
  has_many :phrases, through: :visits
  has_many :place_phrases, -> { order(:position) }, dependent: :delete_all, inverse_of: :place

  geocoded_by :name, latitude: :lat, longitude: :long
  reverse_geocoded_by :lat, :long
  CATEGORIES = { "cafe" => "Café", "ramen" => "Ramen", "combini" => "Combini" }.freeze

  # A job that hasn't finished by then is assumed dead, and a new visitor may start another
  PHRASE_GENERATION_TIMEOUT = 5.minutes

  def phrases_generating?
    phrases_generating_since.present? && phrases_generating_since > PHRASE_GENERATION_TIMEOUT.ago
  end

  # Enqueues PlacePhrasesJob unless the place already has phrases or a job is running.
  # The claim is one conditional UPDATE, so two simultaneous page views start one job.
  def generate_phrases_later
    return if place_phrases.exists? || phrases_generating?

    now = Time.current
    claimed = Place.where(id: id)
                   .where("phrases_generating_since IS NULL OR phrases_generating_since <= ?",
                          PHRASE_GENERATION_TIMEOUT.ago)
                   .update_all(phrases_generating_since: now)
    # Generating either way: if another page view claimed it first, its job is running
    self.phrases_generating_since = now
    PlacePhrasesJob.perform_later(self) if claimed == 1
  end
end
