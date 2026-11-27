# Called by the AI in PhraseFinderChat once it's confident which phrase the
# traveller heard. Saves it as a private "heard" phrase on the visit, which
# puts it on the traveller's study list (status: learning).
class RecordPhraseTool < RubyLLM::Tool
  description "Saves a Japanese phrase the traveller heard to their study list. " \
              "Only call this once you are confident which phrase they heard. Call it once per phrase."
  parameter :japanese, description: "The phrase in natural Japanese, as staff would say it"
  parameter :romaji, description: "The phrase in Hepburn romaji"
  parameter :english, description: "A short, plain English meaning"

  # Phrases saved during this chat turn, so the page can show them
  attr_reader :recorded

  def initialize(visit)
    super()
    @visit = visit
    @recorded = []
  end

  # The return value is what the AI sees as the tool's result
  def execute(japanese:, romaji:, english:)
    japanese = japanese.to_s.strip
    # Exact match only: no case-folding of AI text (see CLAUDE.md, Ruby 3.3.5 constraint)
    return "Already on the traveller's study list." if @visit.phrases.exists?(japanese: japanese)

    @recorded << @visit.phrases.create!(source: :heard, speaker: :staff, japanese: japanese,
                                        romaji: romaji.to_s.strip, english: english.to_s.strip)
    "Saved to the traveller's study list."
  rescue ActiveRecord::RecordInvalid => e
    "Could not save: #{e.record.errors.full_messages.to_sentence}"
  end
end
