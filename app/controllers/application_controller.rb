class ApplicationController < ActionController::Base
  before_action :reject_non_ascii_email, if: :devise_controller?
  before_action :authenticate_user!

  private

  # Ruby 3.3.5 (which we can't upgrade) has memory-safety bugs in String case
  # conversion on crafted input. Devise downcases emails, so stop non-ASCII
  # emails before Devise touches them. See config/brakeman.ignore.
  def reject_non_ascii_email
    email = params.dig(:user, :email)
    return if email.nil? || (email.is_a?(String) && email.ascii_only?)

    redirect_to root_path, alert: "Please use an email address with only standard English letters, numbers and symbols."
  end
end
