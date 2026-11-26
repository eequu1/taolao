require "test_helper"

class ReviewMessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @visit = visits(:konbini_ready)
    sign_in users(:traveller)
  end

  def say(text, **options)
    post visit_review_messages_path(@visit), params: { message: { content: text } }, as: :turbo_stream, **options
  end

  test "a message is saved, shown with a typing bubble, and the AI reply is left to a job" do
    assert_enqueued_with(job: AiMessageJob) do
      say "They said something I did not get"
    end

    assert_response :success
    assert_match "They said something I did not get", response.body
    assert_match "fa-ellipsis", response.body
    assert_equal ["user"], @visit.messages.review.pluck(:role)
  end

  test "the message is saved without surrounding whitespace" do
    say "  Hello?  "
    assert_equal "Hello?", @visit.messages.review.sole.content
  end

  test "an empty message is rejected without calling the AI" do
    assert_no_enqueued_jobs do
      say "  "
    end
    assert_response :unprocessable_entity
    assert_match "Please write a message", response.body
    assert_empty @visit.messages
  end

  test "another user's visit is not found" do
    @visit = visits(:other_users_visit)
    assert_no_enqueued_jobs do
      say "Hi"
    end
    assert_response :not_found
  end
end
