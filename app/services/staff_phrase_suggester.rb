# Asks the AI what staff commonly say to customers at a place, for the
# "phrases you may have heard" list on the review page.
#
#   StaffPhraseSuggester.call(place) # => [{ japanese:, romaji:, english: }, ...]
#
# Returns [] when the AI is unavailable, so the review page still works.
# Results are cached per place: every traveller at the same place gets the same list.
class StaffPhraseSuggester
  MAX_SUGGESTIONS = 8
  AI_ERRORS = [RubyLLM::Error, Faraday::Error, JSON::ParserError].freeze

  INSTRUCTIONS = <<~TEXT.freeze
    You help English-speaking travellers in Japan understand what staff say to them.
    Given a place, list the things staff most often say to customers there, most likely first.
    Use the natural, polite service Japanese staff actually use. Give romaji in Hepburn
    and a short, plain English meaning. Only include phrases staff say, not customer phrases.
  TEXT

  PHRASE_SCHEMA = {
    type: "object",
    properties: {
      phrases: {
        type: "array",
        items: {
          type: "object",
          properties: { japanese: { type: "string" }, romaji: { type: "string" }, english: { type: "string" } },
          required: %w[japanese romaji english],
          additionalProperties: false
        }
      }
    },
    required: ["phrases"],
    additionalProperties: false
  }.freeze

  def self.call(place)
    new(place).call
  end

  def initialize(place)
    @place = place
  end

  def call
    # skip_nil: a failed request isn't cached, so the next visitor tries again
    Rails.cache.fetch(["staff_phrases", @place.id, @place.updated_at.to_i], expires_in: 1.week, skip_nil: true) do
      fetch_suggestions
    end || []
  end

  private

  def fetch_suggestions
    response = RubyLLM.chat.with_instructions(INSTRUCTIONS).with_schema(PHRASE_SCHEMA)
                      .ask("Place: #{@place.name}\nAbout it: #{@place.description}\n" \
                           "List up to #{MAX_SUGGESTIONS} phrases.")
    clean(response.parsed)
  rescue *AI_ERRORS => e
    Rails.logger.warn("[StaffPhraseSuggester] place #{@place.id}: #{e.class}: #{e.message}")
    nil
  end

  # The AI's output is untrusted: keep only well-formed entries, as plain strings
  def clean(data)
    phrases = data.is_a?(Hash) ? Array(data["phrases"]) : []
    phrases.filter_map do |phrase|
      next unless phrase.is_a?(Hash) && phrase["japanese"].is_a?(String) && phrase["japanese"].strip.present?

      { japanese: phrase["japanese"].strip, romaji: phrase["romaji"].to_s.strip, english: phrase["english"].to_s.strip }
    end.first(MAX_SUGGESTIONS)
  end
end
