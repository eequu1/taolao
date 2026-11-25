require "test_helper"

class StaffPhraseSuggesterTest < ActiveSupport::TestCase
  include RubyLLM::TestHelper

  setup { @place = places(:konbini) }

  test "returns the phrases the AI suggests for the place" do
    stub_replies({ phrases: [
      { japanese: "温めますか？", romaji: "Atatamemasu ka?", english: "Shall I heat it up?" },
      { japanese: "袋はご利用ですか？", romaji: "Fukuro wa goriyou desu ka?", english: "Do you need a bag?" }
    ] }.to_json)

    suggestions = StaffPhraseSuggester.call(@place)

    assert_equal 2, suggestions.size
    assert_equal({ japanese: "温めますか？", romaji: "Atatamemasu ka?", english: "Shall I heat it up?" },
                 suggestions.first)
  end

  test "drops malformed suggestions" do
    stub_replies({ phrases: [{ japanese: "", romaji: "x", english: "y" }, { english: "no japanese" },
                             { japanese: "ポイントカードはお持ちですか？", romaji: "Pointo kaado wa omochi desu ka?",
                               english: "Do you have a point card?" }] }.to_json)

    assert_equal ["ポイントカードはお持ちですか？"], StaffPhraseSuggester.call(@place).pluck(:japanese)
  end

  test "an API failure gives no suggestions instead of an error page" do
    stub_replies RubyLLM::ServerError.new("OpenAI is down")
    assert_equal [], StaffPhraseSuggester.call(@place)
  end

  test "a non-JSON reply gives no suggestions" do
    stub_replies "Sorry, I can't help with that."
    assert_equal [], StaffPhraseSuggester.call(@place)
  end
end
