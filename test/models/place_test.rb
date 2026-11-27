require "test_helper"

class PlaceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "the first request for phrases enqueues one job and marks the place as generating" do
    place = places(:konbini)

    assert_enqueued_with(job: PlacePhrasesJob, args: [place]) { place.generate_phrases_later }
    assert place.reload.phrases_generating?
    # A second visitor while the job runs: still generating, no second job
    assert_no_enqueued_jobs { Place.find(place.id).generate_phrases_later }
  end

  test "a place that has phrases doesn't generate more" do
    assert_no_enqueued_jobs { places(:cafe).generate_phrases_later }
  end

  test "a job that never finished is retried after the timeout" do
    place = places(:konbini)
    place.update!(phrases_generating_since: (Place::PHRASE_GENERATION_TIMEOUT + 1.minute).ago)

    assert_enqueued_jobs(1, only: PlacePhrasesJob) { place.generate_phrases_later }
  end
end
