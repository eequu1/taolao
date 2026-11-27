# Generates a place's starter phrases in the background (enqueued by
# Place#generate_phrases_later on the first view of the place page), then
# replaces the "generating…" notice on any open place page via Turbo Streams.
class PlacePhrasesJob < ApplicationJob
  queue_as :default

  def perform(place)
    PlacePhraseGenerator.call(place) unless place.place_phrases.exists?
  ensure
    # Cleared even on failure, so the next page view can try again
    place.update_column(:phrases_generating_since, nil)
    place.place_phrases.reset
    Turbo::StreamsChannel.broadcast_replace_to(
      [place, :phrases], target: "place-phrases",
                         partial: "places/phrases", locals: { place: place, generating: false }
    )
  end
end
