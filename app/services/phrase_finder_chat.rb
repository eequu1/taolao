# The post-visit "what did you hear?" chat. The traveller describes something
# staff said that they didn't understand; the AI asks follow-up questions until
# it's confident, then calls RecordPhraseTool to save the phrase to their study list.
#
#   result = PhraseFinderChat.new(visit).reply_to("They said something like 'pointo kaado'")
#   result.reply    # => the saved assistant Message (nil on error)
#   result.phrases  # => Phrases saved this turn
#
# Only this visit's review messages are sent to the AI (not the prep chat).
class PhraseFinderChat
  Result = Struct.new(:user_message, :reply, :phrases, :chat, :error, keyword_init: true) do
    def error?
      error.present?
    end
  end

  ERROR_TEXT = "Sorry, the assistant isn't available right now. Please try again in a moment."

  def initialize(visit)
    @visit = visit
  end

  # Raises ActiveRecord::RecordInvalid for a blank or over-long message,
  # before anything is sent to the AI.
  def reply_to(text)
    history = @visit.messages.review.order(:id).to_a
    user_message = @visit.messages.review.create!(role: "user", content: text.to_s.strip)

    tool = RecordPhraseTool.new(@visit)
    chat = build_chat(tool, history)
    reply = @visit.messages.review.create!(role: "assistant", content: reply_text(chat.ask(text.to_s.strip)))
    Result.new(user_message: user_message, reply: reply, phrases: tool.recorded, chat: chat)
  rescue *StaffPhraseSuggester::AI_ERRORS => e
    Rails.logger.warn("[PhraseFinderChat] visit #{@visit.id}: #{e.class}: #{e.message}")
    Result.new(user_message: user_message, phrases: tool&.recorded || [], chat: chat, error: ERROR_TEXT)
  end

  private

  def build_chat(tool, history)
    chat = RubyLLM.chat.with_instructions(instructions).with_tools(tool)
    history.each { |message| chat.add_message(role: message.role.to_sym, content: message.content) }
    chat
  end

  def instructions
    <<~TEXT
      You help an English-speaking traveller in Japan work out a phrase staff said to them that
      they didn't understand. Their Japanese level is #{@visit.user.level} out of 100 (1 = beginner).

      Where they were: #{@visit.place.name}. #{@visit.place.description}
      Already on their study list from this visit: #{saved_phrases}

      How to help:
      - Ask one short follow-up question at a time: what was happening, what the staff member was
        doing or holding, any sounds or words they caught.
      - Once you're confident, call record_phrase with the phrase, then tell them in one or two
        sentences what it means and a simple way to reply.
      - If you still can't tell after a few questions, offer the two or three likeliest phrases
        and ask which sounded right. Don't save a phrase you're unsure of.
      - Reply in simple English, in a few sentences, with Japanese and romaji for any phrase you mention.
        Write plain text only: no Markdown, asterisks or headings (the chat shows text as-is).
      - Only help with things heard on this visit; politely steer other topics back.
    TEXT
  end

  def saved_phrases
    list = @visit.phrases.where(source: %i[heard manual]).pluck(:japanese).compact
    list.any? ? list.join(", ") : "none yet"
  end

  # The reply is plain text; a reply that's only a tool call gets a short fallback
  def reply_text(response)
    content = response.content
    content = content.text if content.respond_to?(:text)
    content.to_s.strip.presence&.truncate(Message::MAX_LENGTH) || "Saved to your study list."
  end
end
