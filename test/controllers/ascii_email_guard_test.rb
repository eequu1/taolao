require "test_helper"

# Ruby 3.3.5 can't be upgraded, and its string case conversion is vulnerable to
# crafted input. Devise downcases emails, so non-ASCII emails are rejected first.
class AsciiEmailGuardTest < ActionDispatch::IntegrationTest
  test "sign-up with a non-ASCII email is rejected before Devise sees it" do
    assert_no_difference "User.count" do
      post user_registration_path, params: { user: { email: "İnvalid@example.com", password: "123123",
                                                     password_confirmation: "123123" } }
    end
    assert_redirected_to root_path
  end

  test "sign-in with a non-ASCII email is rejected" do
    post user_session_path, params: { user: { email: "ﬀ@example.com", password: "password" } }
    assert_redirected_to root_path
  end

  test "normal ASCII sign-up still works" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: { user: { email: "New@Example.com", password: "123123",
                                                     password_confirmation: "123123" } }
    end
    assert_equal "new@example.com", User.last.email
  end

  test "normal sign-in still works" do
    post user_session_path, params: { user: { email: "traveller@example.com", password: "password" } }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end
end
