require "test_helper"

class PlacePhraseGeneratorTest < ActiveSupport::TestCase
  include RubyLLM::TestHelper

  setup { @place = places(:konbini) }

  # A minimal complete flow: every stage, with a customer line where one is required
  def flow(extra = [])
    stages = PlacePhrase.stages.keys
    lines = Array.new(PlacePhraseGenerator::MIN_COUNT) do |i|
      stage = stages[i % stages.size]
      { stage: stage, speaker: "customer", japanese: "フレーズ#{i}", romaji: "Fureezu #{i}", english: "Phrase #{i}" }
    end
    { phrases: extra + lines }.to_json
  end

  test "saves a complete conversation in stage order" do
    stub_replies flow([{ stage: "leaving", speaker: "staff", japanese: "ありがとうございました",
                         romaji: "Arigatou gozaimashita", english: "Thank you" }])

    assert PlacePhraseGenerator.call(@place)

    phrases = @place.place_phrases.reload
    assert_equal PlacePhraseGenerator::MIN_COUNT + 1, phrases.size
    assert_equal (1..phrases.size).to_a, phrases.map(&:position)
    assert_equal phrases.map { |p| PlacePhrase.stages[p.stage] }.sort, phrases.map { |p| PlacePhrase.stages[p.stage] }
    # The AI listed it first, but it's a leaving line, so it moves to the leaving stage
    thanks = phrases.find(&:staff?)
    assert_equal "ありがとうございました", thanks.japanese
    assert thanks.leaving?
    assert_equal "arriving", phrases.first.stage
  end

  test "drops malformed phrases" do
    stub_replies flow([{ stage: "Ordering", speaker: "customer", japanese: "x", romaji: "x", english: "x" },
                       { stage: "ordering", speaker: "chef", japanese: "x", romaji: "x", english: "x" },
                       { stage: "ordering", speaker: "customer", japanese: " ", romaji: "x", english: "x" }])

    assert PlacePhraseGenerator.call(@place)
    assert_equal PlacePhraseGenerator::MIN_COUNT, @place.place_phrases.count
  end

  test "asks again when the conversation is missing a stage, and saves nothing if it still is" do
    incomplete = { phrases: Array.new(15) do |i|
      { stage: "ordering", speaker: "customer", japanese: "注文#{i}", romaji: "Chuumon #{i}", english: "Order #{i}" }
    end }.to_json
    stub_replies incomplete, incomplete

    assert_not PlacePhraseGenerator.call(@place)
    assert_equal 0, @place.place_phrases.count
  end

  test "an incomplete first answer is replaced by a complete second one" do
    stub_replies({ phrases: [] }.to_json, flow)
    assert PlacePhraseGenerator.call(@place)
    assert_equal PlacePhraseGenerator::MIN_COUNT, @place.place_phrases.count
  end

  test "an API failure saves nothing" do
    stub_replies RubyLLM::ServerError.new("down"), "not json"
    assert_not PlacePhraseGenerator.call(@place)
    assert_equal 0, @place.place_phrases.count
  end
end
