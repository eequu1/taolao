require "test_helper"

class VisitTest < ActiveSupport::TestCase
  setup do
    @cafe_visit = visits(:cafe_ready)       # place minimum_level 10 -> base 100 XP
    @konbini_visit = visits(:konbini_ready) # place minimum_level 2  -> base 20 XP
  end

  test "a great, confident visit earns the full base XP" do
    @cafe_visit.assign_attributes(self_rating: 5, confidence: 5)
    assert_equal 100, @cafe_visit.visit_experience
  end

  test "a bad, unconfident visit still earns 40% of base XP" do
    @cafe_visit.assign_attributes(self_rating: 1, confidence: 1)
    assert_equal 40, @cafe_visit.visit_experience
  end

  test "middle ratings scale in between" do
    @cafe_visit.assign_attributes(self_rating: 3, confidence: 3)
    assert_equal 68, @cafe_visit.visit_experience # 100 * 0.75 * 0.9 = 67.5
  end

  test "each used phrase earns 2 x minimum_level, counting at most 5" do
    assert_equal 4, @konbini_visit.phrase_experience(1)
    assert_equal 20, @konbini_visit.phrase_experience(5)
    assert_equal 20, @konbini_visit.phrase_experience(6)
  end

  test "complete_review! saves the review, marks phrases used and awards XP" do
    phrase_ids = (0..5).map { |i| phrases(:"konbini_phrase_#{i}").id }

    levels = @konbini_visit.complete_review!(self_rating: 5, confidence: 5, used_phrase_ids: phrase_ids)

    @konbini_visit.reload
    assert @konbini_visit.completed?
    assert_equal 40, @konbini_visit.experience_awarded # 20 visit + 20 phrases (capped at 5)
    assert_equal 40, @konbini_visit.user.experience
    assert_equal 1, levels
    assert phrases(:konbini_phrase_0).reload.used?
  end

  test "reviewing the same visit twice awards nothing the second time" do
    @konbini_visit.complete_review!(self_rating: 5, confidence: 5)
    assert_equal 0, @konbini_visit.complete_review!(self_rating: 5, confidence: 5)
    assert_equal 20, @konbini_visit.user.reload.experience
  end

  test "ratings must be 1-5" do
    assert_raises(ActiveRecord::RecordInvalid) do
      @konbini_visit.complete_review!(self_rating: 0, confidence: 5)
    end
    assert_equal 0, @konbini_visit.user.reload.experience
    assert_not @konbini_visit.reload.completed?
  end

  test "phrases from another visit can't be marked used" do
    @konbini_visit.complete_review!(self_rating: 5, confidence: 5, used_phrase_ids: [phrases(:cafe_hot).id])
    assert_not phrases(:cafe_hot).reload.used?
    assert_equal 20, @konbini_visit.reload.experience_awarded
  end
end

class VisitReviewPhrasesTest < ActiveSupport::TestCase
  setup { @visit = visits(:cafe_ready) }

  test "the review list has this visit's phrases, earlier ones here and the place's key phrases, once each" do
    choices = @visit.review_phrase_choices

    assert_equal [phrases(:cafe_hot), phrases(:heard_phrase), phrases(:manual_phrase)], choices.first(3)
    assert_includes choices, phrases(:earlier_cafe_phrase)
    assert_includes choices, place_phrases(:cafe_greeting)
    assert_not_includes choices, phrases(:konbini_hot) # another place
    # ラテをください is both an earlier phrase and a key phrase: listed once
    assert_equal 1, choices.count { |phrase| phrase.japanese == "ラテをください" }
  end

  test "ticked key phrases and earlier phrases are copied onto the visit as used, and earn XP" do
    @visit.complete_review!(self_rating: 5, confidence: 5,
                            used_phrase_ids: [phrases(:earlier_cafe_phrase).id],
                            used_place_phrase_ids: [place_phrases(:cafe_greeting).id])

    used = @visit.phrases.where(used: true)
    assert_equal %w[いらっしゃいませ レシートをください].sort, used.pluck(:japanese).sort
    assert used.find_by(japanese: "いらっしゃいませ").staff?
    assert_not phrases(:earlier_cafe_phrase).reload.used? # the original stays as it was
    assert_equal 140, @visit.reload.experience_awarded # 100 visit + 2 phrases x 20
  end

  test "a heard phrase on this visit can be marked used" do
    @visit.complete_review!(self_rating: 5, confidence: 5, used_phrase_ids: [phrases(:heard_phrase).id])
    assert phrases(:heard_phrase).reload.used?
  end

  test "a key phrase already on the visit is marked used, not duplicated" do
    @visit.phrases.create!(japanese: "いらっしゃいませ", romaji: "Irasshaimase", english: "Welcome")

    assert_difference("Phrase.count", 0) do
      @visit.complete_review!(self_rating: 5, confidence: 5, used_place_phrase_ids: [place_phrases(:cafe_greeting).id])
    end
    assert @visit.phrases.find_by(japanese: "いらっしゃいませ").used?
  end

  test "other users' phrases and other places' key phrases are ignored" do
    other = visits(:other_users_visit).phrases.create!(japanese: "他人", romaji: "Tanin", english: "Someone else's")
    konbini_line = places(:konbini).place_phrases.create!(position: 1, stage: :ordering, japanese: "これ",
                                                          romaji: "Kore", english: "This")

    assert_no_difference("Phrase.count") do
      @visit.complete_review!(self_rating: 5, confidence: 5, used_phrase_ids: [other.id],
                              used_place_phrase_ids: [konbini_line.id])
    end
    assert_equal 100, @visit.reload.experience_awarded
  end
end
