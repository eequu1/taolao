# The post-visit "what did you hear?" chat (separate from MessagesController,
# which is left for the Prep stage's "Prepare with AI" chat).
class ReviewMessagesController < ApplicationController
  before_action :set_visit

  # Saves the user's message and shows a typing bubble; AiMessageJob gets the AI's
  # reply in the background and broadcasts it to the review page.
  def create
    @user_message = @visit.messages.review.create!(role: "user", content: params.dig(:message, :content).to_s.strip)
    AiMessageJob.perform_later(@user_message)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path }
    end
  rescue ActiveRecord::RecordInvalid
    render_invalid
  end

  private

  def set_visit
    @visit = current_user.visits.find(params[:visit_id])
  end

  def render_invalid
    respond_to do |format|
      format.turbo_stream { render :invalid, status: :unprocessable_entity }
      format.html { redirect_to chat_path, alert: invalid_message }
    end
  end

  def chat_path
    review_visit_path(@visit, anchor: "chat")
  end

  def invalid_message
    "Please write a message (up to #{Message::MAX_LENGTH} characters)."
  end
  helper_method :invalid_message
end
