require "test_helper"

class VisitsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include RubyLLM::TestHelper

  setup do
    @user = users(:traveller)
    @visit = visits(:konbini_ready) # konbini minimum_level 2 -> 20 base XP
    sign_in @user
  end

  test "review page has the rating form, the suggestions frame and the chat" do
    get review_visit_path(@visit)
    assert_response :success
    assert_select "input[type=radio][name='visit[self_rating]']", 5
    assert_select "input[type=radio][name='visit[confidence]']", 5
    assert_select "input[type=checkbox][value='#{phrases(:konbini_phrase_0).id}']"
    assert_select "turbo-frame#phrase-suggestions[src='#{phrase_suggestions_visit_path(@visit)}']"
    assert_select "form#chat-form[action='#{visit_review_messages_path(@visit)}']"
  end

  test "submitting the review completes the visit, awards XP and returns to the review page" do
    patch visit_path(@visit), params: { visit: { self_rating: 5, confidence: 5,
                                                 used_phrase_ids: [phrases(:konbini_phrase_0).id] } }

    assert_redirected_to review_visit_path(@visit)
    assert @visit.reload.completed?
    assert_equal 24, @visit.experience_awarded # 20 visit + 4 for one phrase
    assert_equal 24, @user.reload.experience
  end

  test "after reviewing, the XP card replaces the form and the chat stays" do
    patch visit_path(@visit), params: { visit: { self_rating: 5, confidence: 5 } } # 20 XP: still level 1
    patch visit_path(visits(:cafe_ready)), params: { visit: { self_rating: 5, confidence: 5 } } # +100 -> level 3
    follow_redirect!

    assert_select ".xp-earned", text: /\+100 XP/
    assert_select ".level-up", text: /level 3/i
    assert_select "input[name='visit[self_rating]']", 0
    assert_select "form#chat-form"
  end

  test "an incomplete review re-renders the form without awarding XP" do
    patch visit_path(@visit), params: { visit: { confidence: 5 } }

    assert_response :unprocessable_entity
    assert_not @visit.reload.completed?
    assert_equal 0, @user.reload.experience
  end

  test "the review page shows earlier chat messages" do
    @visit.messages.create!(purpose: :review, role: "assistant", content: "What was the staff member holding?")
    @visit.messages.create!(purpose: :prep, role: "assistant", content: "Prep chat message")

    get review_visit_path(@visit)
    assert_select ".chat-bubble", text: /staff member holding/
    assert_select ".chat-bubble", text: /Prep chat message/, count: 0
  end

  test "phrase suggestions come from the AI with Add buttons" do
    stub_replies({ phrases: [{ japanese: "温めますか？", romaji: "Atatamemasu ka?", english: "Shall I heat it up?" },
                             { japanese: "フレーズ0", romaji: "Fureezu 0", english: "Phrase 0" }] }.to_json)

    get phrase_suggestions_visit_path(@visit)

    assert_response :success
    assert_select "turbo-frame#phrase-suggestions"
    assert_select "#suggestion_0 form[action='#{visit_phrases_path(@visit)}']"
    assert_select "#suggestion_1 .added" # フレーズ0 is already one of this visit's phrases
  end

  test "suggestions degrade gracefully when the AI is unavailable" do
    stub_replies RubyLLM::ServerError.new("down")
    get phrase_suggestions_visit_path(@visit)
    assert_response :success
    assert_select "turbo-frame#phrase-suggestions p", text: /aren't available/
  end

  test "the summary lists the phrases the user heard" do
    visit = visits(:cafe_ready)
    visit.complete_review!(self_rating: 4, confidence: 4)
    get visit_path(visit)
    assert_select ".phrase-card .english", text: "Would you like a bag?"
  end

  test "an unreviewed visit's summary links to the review" do
    @visit.completed!
    get visit_path(@visit)
    assert_select "a[href='#{review_visit_path(@visit)}']"
  end

  test "I'm ready! marks the visit ready and shows the listening page" do
    @visit.active!
    patch ready_visit_path(@visit)

    assert_redirected_to visit_path(@visit)
    assert @visit.reload.ready?
    follow_redirect!
    assert_select ".listening-text", text: "You shouldn't be looking at me"
    assert_select "form[action='#{complete_visit_path(@visit)}']"
  end

  test "Interaction over completes the visit and goes to the review" do
    patch complete_visit_path(@visit)

    assert_redirected_to review_visit_path(@visit)
    assert @visit.reload.completed?
  end

  test "another user's visit can't be marked ready or completed" do
    other = visits(:other_users_visit)
    patch complete_visit_path(other)
    assert_response :not_found
    assert other.reload.ready?
  end

  test "another user's visit can't be viewed" do
    get review_visit_path(visits(:other_users_visit))
    assert_response :not_found
  end

  test "another user's visit can't be reviewed" do
    other = visits(:other_users_visit)
    patch visit_path(other), params: { visit: { self_rating: 5, confidence: 5 } }
    assert_response :not_found
    assert_not other.reload.completed?
  end

  test "signed-out users are sent to sign in" do
    sign_out @user
    get review_visit_path(@visit)
    assert_redirected_to new_user_session_path
  end
end
