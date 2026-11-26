# Gets the AI's reply to a message in the post-visit "what did you hear?" chat and
# broadcasts it to the review page (which subscribes with turbo_stream_from visit, :review_chat),
# replacing the typing bubble that ReviewMessagesController#create showed.
class AiMessageJob < ApplicationJob
  queue_as :default

  # The message (or its visit) was deleted before the job ran
  discard_on ActiveJob::DeserializationError

  # AI errors aren't retried: PhraseFinderChat rescues them and returns result.error
  def perform(user_message)
    visit = user_message.visit
    result = PhraseFinderChat.new(visit).reply_to(user_message)
    broadcast_result(visit, result)
  end

  private

  def broadcast_result(visit, result)
    stream = [visit, :review_chat]
    Turbo::StreamsChannel.broadcast_remove_to(stream, target: "chat-typing")

    result.phrases.each do |phrase|
      append(stream, "review_messages/saved_phrase", phrase: phrase)
    end

    if result.reply
      append(stream, "review_messages/message", message: result.reply)
    else
      append(stream, "review_messages/error", error: result.error)
    end
  end

  def append(stream, partial, locals)
    Turbo::StreamsChannel.broadcast_append_to(stream, target: "chat-messages", partial: partial, locals: locals)
  end
end
