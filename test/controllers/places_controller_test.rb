require "test_helper"

class PlacesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup { sign_in users(:traveller) }

  test "first view of a place starts generating phrases in the background and says so" do
    place = places(:konbini)

    assert_enqueued_with(job: PlacePhrasesJob, args: [place]) { get place_path(place) }

    assert_response :success
    assert_select "turbo-cable-stream-source"
    assert_select "#place-phrases .phrases-generating", text: /Generating phrases/
  end

  test "a place with phrases shows them grouped by stage, without starting a job" do
    assert_no_enqueued_jobs { get place_path(places(:cafe)) }

    assert_select "#place-phrases .phrase-stage", text: "Arriving"
    assert_select "#place-phrases .phrase-card.staff-line .japanese", text: "いらっしゃいませ"
    assert_select "#place-phrases .phrase-card .japanese", text: "ラテをください"
    assert_select ".phrases-generating", 0
  end
end

class PlacesControllerYourPhrasesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "the place page lists the user's own phrases from visits there, skipping key phrases" do
    sign_in users(:traveller)
    get place_path(places(:cafe))

    assert_select "h2", text: "Your phrases"
    assert_select ".phrase-card.staff-line .japanese", text: "レシートをください"
    assert_select ".phrase-card .japanese", text: "ラテをください", count: 1 # already a key phrase
  end

  test "other users don't see someone's phrases" do
    sign_in users(:other_traveller)
    get place_path(places(:cafe))

    assert_select "h2", text: "Your phrases", count: 0
    assert_select ".japanese", text: "レシートをください", count: 0
  end
end
