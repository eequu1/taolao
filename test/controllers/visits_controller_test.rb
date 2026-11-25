require "test_helper"

class VisitsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:traveller)
    @visit = visits(:konbini_ready) # konbini minimum_level 2 -> 20 base XP
    sign_in @user
  end

  test "review form shows the ratings and the prepped phrases" do
    get review_visit_path(@visit)
    assert_response :success
    assert_select "input[type=radio][name='visit[self_rating]']", 5
    assert_select "input[type=radio][name='visit[confidence]']", 5
    assert_select "input[type=checkbox][value='#{phrases(:konbini_phrase_0).id}']"
  end

  test "submitting the review completes the visit and awards XP" do
    patch visit_path(@visit), params: { visit: { self_rating: 5, confidence: 5,
                                                 used_phrase_ids: [phrases(:konbini_phrase_0).id] } }

    assert_redirected_to visit_path(@visit)
    assert @visit.reload.completed?
    assert_equal 24, @visit.experience_awarded # 20 visit + 4 for one phrase
    assert_equal 24, @user.reload.experience
  end

  test "the summary shows XP earned and a level-up banner" do
    patch visit_path(@visit), params: { visit: { self_rating: 5, confidence: 5 } } # 20 XP: still level 1
    patch visit_path(visits(:cafe_ready)), params: { visit: { self_rating: 5, confidence: 5 } } # +100 -> level 3
    follow_redirect!

    assert_select ".xp-earned", text: /\+100 XP/
    assert_select ".level-up", text: /level 3/i
  end

  test "an incomplete review re-renders the form without awarding XP" do
    patch visit_path(@visit), params: { visit: { confidence: 5 } }

    assert_response :unprocessable_entity
    assert_not @visit.reload.completed?
    assert_equal 0, @user.reload.experience
  end

  test "a reviewed visit can't be reviewed again" do
    @visit.complete_review!(self_rating: 5, confidence: 5)
    get review_visit_path(@visit)
    assert_redirected_to visit_path(@visit)
  end

  test "a reviewed visit's summary has the heard-phrases section and form" do
    @visit.complete_review!(self_rating: 4, confidence: 4)
    get visit_path(@visit)
    assert_select "#heard h4", text: /heard but didn't understand/
    assert_select "form#manual-phrase-form[action='#{visit_phrases_path(@visit)}']"
  end

  test "an unreviewed visit's summary links to the review" do
    get visit_path(@visit)
    assert_select "a[href='#{review_visit_path(@visit)}']"
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
