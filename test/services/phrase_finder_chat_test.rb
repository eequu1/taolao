require "test_helper"

class PhraseFinderChatTest < ActiveSupport::TestCase
  include RubyLLM::TestHelper

  setup do
    @visit = visits(:konbini_ready)
    @chat = PhraseFinderChat.new(@visit)
  end

  test "a clarifying question is saved as a review message" do
    stub_replies "Was the staff member holding anything when they said it?"

    result = @chat.reply_to("The cashier said something like 'pointo kaado'")

    assert_equal ["user", "assistant"], @visit.messages.review.order(:id).pluck(:role)
    assert_equal "Was the staff member holding anything when they said it?", result.reply.content
    assert_empty result.phrases
  end

  test "when the AI is confident it records the phrase on the user's study list" do
    stub_replies tool_call(:record_phrase, japanese: "ポイントカードはお持ちですか？",
                                           romaji: "Pointo kaado wa omochi desu ka?",
                                           english: "Do you have a point card?"),
                 "That was 'Do you have a point card?'. I've added it to your study list."

    result = nil
    assert_difference "@visit.phrases.heard.count", 1 do
      result = @chat.reply_to("They held up a card and said 'pointo kaado wa'")
    end

    phrase = result.phrases.sole
    assert_equal "ポイントカードはお持ちですか？", phrase.japanese
    assert phrase.learning?
    assert_equal @visit.place, phrase.visit.place
  end

  test "recording the same phrase twice on a visit doesn't duplicate it" do
    @visit.phrases.create!(source: :heard, japanese: "温めますか？", english: "Shall I heat it up?")
    stub_replies tool_call(:record_phrase, japanese: "温めますか？", romaji: "Atatamemasu ka?",
                                           english: "Shall I heat it up?"),
                 "It's already on your list."

    assert_no_difference "Phrase.count" do
      @chat.reply_to("Something about atatame")
    end
  end

  test "the AI only sees this visit's review chat, not the prep chat" do
    @visit.messages.create!(purpose: :prep, role: "user", content: "Prep question")
    @visit.messages.create!(purpose: :review, role: "user", content: "Earlier review question")
    @visit.messages.create!(purpose: :review, role: "assistant", content: "Earlier review answer")
    stub_replies "OK"

    sent = @chat.reply_to("New question").chat.messages.select { |m| %i[user assistant].include?(m.role) }

    assert_equal ["Earlier review question", "Earlier review answer", "New question", "OK"], sent.map(&:content)
  end

  test "an API failure keeps the user's message and returns an apology" do
    stub_replies RubyLLM::ServerError.new("OpenAI is down")

    result = @chat.reply_to("Hello?")

    assert result.error?
    assert_equal ["user"], @visit.messages.review.pluck(:role)
  end

  test "blank or over-long messages are rejected before calling the AI" do
    assert_raises(ActiveRecord::RecordInvalid) { @chat.reply_to("   ") }
    assert_raises(ActiveRecord::RecordInvalid) { @chat.reply_to("a" * 2001) }
    assert_empty @visit.messages
  end
end
