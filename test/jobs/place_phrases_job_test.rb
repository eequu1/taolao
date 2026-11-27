require "test_helper"

class PlacePhrasesJobTest < ActiveJob::TestCase
  include RubyLLM::TestHelper

  setup do
    @place = places(:konbini)
    @place.update!(phrases_generating_since: Time.current)
  end

  test "saves the phrases and pushes them to the open place page" do
    stages = PlacePhrase.stages.keys
    stub_replies({ phrases: Array.new(PlacePhraseGenerator::MIN_COUNT) do |i|
      { stage: stages[i % stages.size], speaker: "customer", japanese: "フレーズ#{i}",
        romaji: "Fureezu #{i}", english: "Phrase #{i}" }
    end }.to_json)

    streams = capture_turbo_stream_broadcasts([@place, :phrases]) { PlacePhrasesJob.perform_now(@place) }

    assert_equal PlacePhraseGenerator::MIN_COUNT, @place.place_phrases.count
    assert_nil @place.reload.phrases_generating_since
    assert_equal "replace", streams.first["action"]
    assert_includes streams.first.to_html, "フレーズ0"
  end

  test "a failure clears the generating flag and tells the page" do
    stub_replies RubyLLM::ServerError.new("down"), RubyLLM::ServerError.new("down")

    streams = capture_turbo_stream_broadcasts([@place, :phrases]) { PlacePhrasesJob.perform_now(@place) }

    assert_nil @place.reload.phrases_generating_since
    assert_includes streams.first.to_html, "couldn't get phrases"
  end
end
