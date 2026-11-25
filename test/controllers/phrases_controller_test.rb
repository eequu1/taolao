require "test_helper"

class PhrasesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:traveller)
    @visit = visits(:konbini_ready)
    @visit.complete_review!(self_rating: 4, confidence: 4) # phrases are added after the review
    sign_in @user
  end

  def phrase_params(**overrides)
    { phrase: { japanese: "温めますか？", romaji: "Atatamemasu ka?", english: "Shall I heat it up?" }.merge(overrides) }
  end

  test "adding a phrase by hand creates a manual phrase on the visit" do
    assert_difference "@visit.phrases.manual.count", 1 do
      post visit_phrases_path(@visit), params: phrase_params
    end
    assert_redirected_to visit_path(@visit, anchor: "heard")
  end

  test "Turbo requests get the new phrase appended without a reload" do
    post visit_phrases_path(@visit), params: phrase_params, as: :turbo_stream
    assert_response :success
    assert_match "温めますか？", response.body
    assert_match 'action="append" target="heard-phrases"', response.body
  end

  test "a phrase picked from the suggestions is saved as heard" do
    post visit_phrases_path(@visit), params: phrase_params(source: "heard")
    assert @visit.phrases.last.heard?
  end

  test "the source can't be set to prepped from the form" do
    post visit_phrases_path(@visit), params: phrase_params(source: "prepped")
    assert @visit.phrases.last.manual?
  end

  test "only one of the three fields is needed" do
    assert_difference "Phrase.count", 1 do
      post visit_phrases_path(@visit), params: { phrase: { romaji: "Pointo kaado" } }
    end
  end

  test "an empty phrase is rejected" do
    assert_no_difference "Phrase.count" do
      post visit_phrases_path(@visit), params: { phrase: { japanese: "", romaji: "", english: "" } },
                                       as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "adding phrases awards no XP" do
    assert_no_difference "@user.reload.experience" do
      post visit_phrases_path(@visit), params: phrase_params
    end
  end

  test "phrases can't be added before the visit is reviewed" do
    unreviewed = visits(:cafe_ready)
    assert_no_difference "Phrase.count" do
      post visit_phrases_path(unreviewed), params: phrase_params
    end
    assert_redirected_to visit_path(unreviewed)
  end

  test "phrases can't be added to another user's visit" do
    post visit_phrases_path(visits(:other_users_visit)), params: phrase_params
    assert_response :not_found
  end
end
