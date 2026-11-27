require "test_helper"

class PhrasesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:traveller)
    @visit = visits(:konbini_ready)
    sign_in @user
  end

  def add_params(index: 0, **overrides)
    { suggestion: index,
      phrase: { japanese: "温めますか？", romaji: "Atatamemasu ka?", english: "Shall I heat it up?" }.merge(overrides) }
  end

  test "adding a suggestion saves it as a heard phrase on the user's study list" do
    assert_difference "@visit.phrases.heard.count", 1 do
      post visit_phrases_path(@visit), params: add_params
    end
    assert @visit.phrases.last.learning?
    assert @visit.phrases.last.staff? # suggestions are things staff say
    assert_redirected_to review_visit_path(@visit)
  end

  test "works before the visit is reviewed" do
    assert_not @visit.reviewed?
    assert_difference("Phrase.count", 1) { post visit_phrases_path(@visit), params: add_params }
  end

  test "Turbo requests flip the suggestion to Added" do
    post visit_phrases_path(@visit), params: add_params(index: 3), as: :turbo_stream
    assert_response :success
    assert_match 'action="replace" target="suggestion_3"', response.body
    assert_match "Added", response.body
  end

  test "adding the same suggestion twice doesn't duplicate it" do
    post visit_phrases_path(@visit), params: add_params
    assert_no_difference("Phrase.count") { post visit_phrases_path(@visit), params: add_params }
  end

  test "a suggestion without Japanese is rejected" do
    assert_no_difference "Phrase.count" do
      post visit_phrases_path(@visit), params: add_params(japanese: "", romaji: "", english: ""), as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "adding phrases awards no XP" do
    assert_no_difference("@user.reload.experience") { post visit_phrases_path(@visit), params: add_params }
  end

  test "phrases can't be added to another user's visit" do
    post visit_phrases_path(visits(:other_users_visit)), params: add_params
    assert_response :not_found
  end
end
