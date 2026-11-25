require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup { @user = users(:traveller) }

  test "total XP needed to reach a level grows by 25 x level each step" do
    assert_equal 0, User.experience_for_level(1)
    assert_equal 25, User.experience_for_level(2)
    assert_equal 75, User.experience_for_level(3)
    assert_equal 123_750, User.experience_for_level(100)
  end

  test "level_for turns total XP into a level" do
    assert_equal 1, User.level_for(0)
    assert_equal 1, User.level_for(24)
    assert_equal 2, User.level_for(25)
    assert_equal 3, User.level_for(75)
  end

  test "level is capped at 100" do
    assert_equal 100, User.level_for(10_000_000)
  end

  test "gain_experience! can jump several levels and returns how many" do
    assert_equal 2, @user.gain_experience!(80)
    assert_equal 80, @user.reload.experience
    assert_equal 3, @user.level
  end

  test "XP keeps accumulating at max level" do
    @user.gain_experience!(200_000)
    assert_equal 100, @user.level
    assert_equal 200_000, @user.experience
    assert_equal 0, @user.gain_experience!(1)
  end

  test "progress within the current level" do
    @user.gain_experience!(35) # level 2 starts at 25, level 3 at 75
    assert_equal 10, @user.experience_into_level
    assert_equal 50, @user.experience_for_next_level
  end

  test "no next level at max" do
    @user.gain_experience!(200_000)
    assert_nil @user.experience_for_next_level
  end
end
