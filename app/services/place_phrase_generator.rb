# Asks the AI for ~20 phrases a traveller needs at a place, covering a full
# ordering conversation from walking in to leaving, and saves them as the place's
# PlacePhrases. Run in the background by PlacePhrasesJob.
#
#   PlacePhraseGenerator.call(place) # => true if phrases were saved
#
# The AI's answer is only saved if it covers every stage of the flow; otherwise it
# asks once more, then gives up (nothing saved, so the next page view tries again).
class PlacePhraseGenerator
  TARGET_COUNT = 20
  MIN_COUNT = 12
  MAX_COUNT = 25
  ATTEMPTS = 2
  AI_ERRORS = [RubyLLM::Error, Faraday::Error, JSON::ParserError].freeze
  # Without these the traveller can't get from "hello" to "goodbye"
  STAGES_NEEDING_CUSTOMER_LINE = %w[arriving ordering paying].freeze

  INSTRUCTIONS = <<~TEXT.freeze
    You help English-speaking travellers in Japan get ready to order at a real place.
    Given a place, write about #{TARGET_COUNT} short phrases for ordering food or drink there,
    in the order they come up, so together they cover a full conversation from walking in
    to leaving. Match how this kind of place works (for example a ramen shop's ticket
    machine and counter seats, a café's counter and drink sizes, or a convenience store's
    register, heating food and bags).

    Each phrase has a stage:
    - arriving: being greeted, number of people, seating, asking for a menu
    - ordering: asking for recommendations and ordering
    - details: sizes, hot or iced, toppings, eat in or take away, heating, allergies
    - paying: the total, paying by cash or card, receipts, bags, point cards
    - leaving: thanks and goodbyes
    Include every stage. Mostly write what the customer says (simple, polite Japanese a
    beginner can manage), plus the key lines staff say, so the traveller can follow along.
    Several phrases can be alternatives for the same moment. Give romaji in Hepburn and a
    short, plain English meaning.
  TEXT

  SCHEMA = {
    type: "object",
    properties: {
      phrases: {
        type: "array",
        items: {
          type: "object",
          properties: {
            stage: { type: "string", enum: PlacePhrase.stages.keys },
            speaker: { type: "string", enum: PlacePhrase.speakers.keys },
            japanese: { type: "string" },
            romaji: { type: "string" },
            english: { type: "string" }
          },
          required: %w[stage speaker japanese romaji english],
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
    phrases = ATTEMPTS.times.lazy.filter_map { fetch_phrases }.first # stops at the first good answer
    save_phrases(phrases) if phrases
    phrases.present?
  end

  private

  def fetch_phrases
    response = RubyLLM.chat.with_instructions(INSTRUCTIONS).with_schema(SCHEMA).ask(prompt)
    phrases = clean(response.parsed)
    return phrases if complete_flow?(phrases)

    Rails.logger.warn("[PlacePhraseGenerator] place #{@place.id}: incomplete conversation, #{phrases.size} phrases")
    nil
  rescue *AI_ERRORS => e
    Rails.logger.warn("[PlacePhraseGenerator] place #{@place.id}: #{e.class}: #{e.message}")
    nil
  end

  def prompt
    category = Place::CATEGORIES[@place.category] || @place.category
    "Place: #{@place.name}\nKind of place: #{category.presence || 'unknown'}\n" \
      "About it: #{@place.description}\nWrite about #{TARGET_COUNT} phrases."
  end

  # The AI's output is untrusted: keep well-formed entries, as plain strings, in the
  # flow's stage order (stable, so alternatives keep the AI's order within a stage).
  # Stage and speaker are compared exactly against the enum keys.
  def clean(data)
    raw = data.is_a?(Hash) ? Array(data["phrases"]) : []
    phrases = raw.filter_map { |phrase| clean_phrase(phrase) }.first(MAX_COUNT)
    phrases.each_with_index.sort_by { |phrase, i| [PlacePhrase.stages[phrase[:stage]], i] }.map(&:first)
  end

  def clean_phrase(phrase)
    return unless phrase.is_a?(Hash)
    return unless PlacePhrase.stages.key?(phrase["stage"]) && PlacePhrase.speakers.key?(phrase["speaker"])

    text = phrase_text(phrase)
    { stage: phrase["stage"], speaker: phrase["speaker"], **text } if text
  end

  # All three texts, stripped, or nil if any is missing or too long
  def phrase_text(phrase)
    text = %w[japanese romaji english].to_h { |key| [key.to_sym, phrase[key].is_a?(String) ? phrase[key].strip : ""] }
    text unless text.values.any? { |value| value.empty? || value.length > 200 }
  end

  def complete_flow?(phrases)
    return false if phrases.size < MIN_COUNT

    PlacePhrase.stages.keys.all? { |stage| phrases.any? { |p| p[:stage] == stage } } &&
      STAGES_NEEDING_CUSTOMER_LINE.all? { |stage| phrases.any? { |p| p[:stage] == stage && p[:speaker] == "customer" } }
  end

  # Replaces any existing set in one transaction, so the page never shows half a conversation
  def save_phrases(phrases)
    PlacePhrase.transaction do
      @place.place_phrases.delete_all
      phrases.each_with_index { |attrs, i| @place.place_phrases.create!(attrs.merge(position: i + 1)) }
    end
  end
end
