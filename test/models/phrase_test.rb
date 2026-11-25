require "test_helper"

class PhraseTest < ActiveSupport::TestCase
  setup { @user = users(:traveller) }

  test "memorizing a used phrase awards 5 x minimum_level" do
    phrase = phrases(:konbini_hot) # used, konbini minimum_level 2

    assert_equal 10, phrase.memorize!
    assert phrase.reload.memorized?
    assert_not_nil phrase.memorized_at
    assert_equal 10, @user.reload.experience
  end

  test "a heard phrase can be memorized without being used" do
    assert_equal 50, phrases(:heard_phrase).memorize! # cafe minimum_level 10
  end

  test "an unused prepped or manual phrase can't be memorized" do
    [phrases(:konbini_phrase_0), phrases(:manual_phrase)].each do |phrase|
      assert_raises(ActiveRecord::RecordInvalid) { phrase.memorize! }
      assert phrase.reload.learning?
    end
    assert_equal 0, @user.reload.experience
  end

  test "un-memorizing and memorizing again pays nothing the second time" do
    phrase = phrases(:konbini_hot)
    phrase.memorize!
    phrase.unmemorize!
    assert phrase.reload.learning?

    assert_equal 0, phrase.memorize!
    assert phrase.reload.memorized?
    assert_equal 10, @user.reload.experience
  end

  test "the same Japanese text pays only once per user" do
    phrases(:konbini_hot).memorize!
    duplicate = phrases(:cafe_hot)
    duplicate.update!(used: true)

    assert_equal 0, duplicate.memorize!
    assert duplicate.reload.memorized?
    assert_equal 10, @user.reload.experience
  end
end
