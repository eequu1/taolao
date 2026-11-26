require "test_helper"

class AiMessageJobTest < ActiveJob::TestCase
  include RubyLLM::TestHelper

  setup do
    @visit = visits(:konbini_ready)
  end

  # Saves the user's message (as the controller does) and runs the job on it
  def run_job_for(text)
    message = @visit.messages.review.create!(role: "user", content: text)
    capture_turbo_stream_broadcasts([@visit, :review_chat]) { AiMessageJob.perform_now(message) }
  end

  test "the AI's reply is saved and replaces the typing bubble" do
    stub_replies "What was the staff member doing when they said it?"

    streams = run_job_for "They said something I did not get"

    assert_equal ["user", "assistant"], @visit.messages.review.order(:id).pluck(:role)
    assert_equal ["remove", "append"], streams.map { |stream| stream["action"] }
    assert_equal "chat-typing", streams.first["target"]
    assert_match "What was the staff member doing", streams.last.to_html
  end

  test "a phrase the AI records is broadcast as a study-list card before the reply" do
    stub_replies tool_call(:record_phrase, japanese: "ポイントカードはお持ちですか？",
                                           romaji: "Pointo kaado wa omochi desu ka?",
                                           english: "Do you have a point card?"),
                 "That was 'Do you have a point card?'."

    streams = run_job_for "They held up a card and said 'pointo kaado'"

    assert @visit.phrases.heard.exists?(japanese: "ポイントカードはお持ちですか？")
    card, reply = streams.last(2).map(&:to_html)
    assert_match "Added to your study list", card
    assert_match "ポイントカードはお持ちですか？", card
    assert_match "Do you have a point card?", reply
  end

  test "an AI failure replaces the typing bubble with an apology" do
    stub_replies RubyLLM::ServerError.new("down")

    streams = run_job_for "Hello?"

    assert_equal ["user"], @visit.messages.review.pluck(:role)
    assert_equal "chat-typing", streams.first["target"]
    assert_match "isn't available right now", streams.last.text
  end

  test "a message deleted before the job runs is discarded" do
    message = @visit.messages.review.create!(role: "user", content: "Hello?")
    AiMessageJob.perform_later(message)
    message.destroy

    assert_nothing_raised { perform_enqueued_jobs }
  end
end
