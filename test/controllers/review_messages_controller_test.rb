require "test_helper"

class ReviewMessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include RubyLLM::TestHelper

  setup do
    @visit = visits(:konbini_ready)
    sign_in users(:traveller)
  end

  def say(text, **options)
    post visit_review_messages_path(@visit), params: { message: { content: text } }, as: :turbo_stream, **options
  end

  test "a message gets the AI's reply appended to the chat" do
    stub_replies "What was the staff member doing when they said it?"

    say "They said something I did not get"

    assert_response :success
    assert_match "They said something I did not get", response.body
    assert_match "What was the staff member doing", response.body
    assert_equal 2, @visit.messages.review.count
  end

  test "a phrase the AI records shows up as a study-list card in the chat" do
    stub_replies tool_call(:record_phrase, japanese: "ポイントカードはお持ちですか？",
                                           romaji: "Pointo kaado wa omochi desu ka?",
                                           english: "Do you have a point card?"),
                 "That was 'Do you have a point card?'."

    say "They held up a card and said 'pointo kaado'"

    assert_match "Added to your study list", response.body
    assert_match "ポイントカードはお持ちですか？", response.body
    assert @visit.phrases.heard.exists?(japanese: "ポイントカードはお持ちですか？")
  end

  test "an AI failure shows an apology on the form" do
    stub_replies RubyLLM::ServerError.new("down")
    say "Hello?"
    assert_response :success
    assert_match "isn&#39;t available right now", response.body
  end

  test "an empty message is rejected without calling the AI" do
    say "  "
    assert_response :unprocessable_entity
    assert_match "Please write a message", response.body
    assert_empty @visit.messages
  end

  test "another user's visit is not found" do
    @visit = visits(:other_users_visit)
    say "Hi"
    assert_response :not_found
  end
end
