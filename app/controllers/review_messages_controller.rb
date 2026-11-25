# The post-visit "what did you hear?" chat (separate from MessagesController,
# which is left for the Prep stage's "Prepare with AI" chat).
class ReviewMessagesController < ApplicationController
  before_action :set_visit

  # Synchronous: the AI reply arrives in the same request (a few seconds),
  # while Turbo shows "…" on the send button.
  def create
    @result = PhraseFinderChat.new(@visit).reply_to(params.dig(:message, :content))
    @user_message = @result.user_message

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path, alert: @result.error }
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
