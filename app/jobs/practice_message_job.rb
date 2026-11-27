class PracticeMessageJob < ApplicationJob
  queue_as :default

  SYSTEM_PROMPT = <<~PROMPT
    You are a friendly staff member at a shop in Japan.
    A traveller is practising ordering in Japanese before their real visit.
    Speak like real staff: natural, polite Japanese, one short line at a time.

    The chat starts with "(The customer comes to you.)".
    Your first line is what real staff say at that moment in this kind of shop.
    Think about where the customer is: at a combini they are paying at the register,
    so staff ask about a point card, heating food or a bag, not what they want to order.
    The 3 choices must fit what you just said.

    Always answer with JSON only (no Markdown, no ```), in this exact format:
    {
      "staff_japanese": "your next line in Japanese",
      "staff_english": "its English meaning",
      "choices": [
        { "japanese": "...", "romaji": "...", "english": "..." },
        { "japanese": "...", "romaji": "...", "english": "..." },
        { "japanese": "...", "romaji": "...", "english": "..." }
      ]
    }
    The 3 choices are short, simple replies the traveller could say next.
  PROMPT

  def perform(visit)
    @visit = visit

    @ruby_llm_chat = RubyLLM.chat
    build_conversation_history
    response = @ruby_llm_chat.with_instructions(instructions).complete
    answer = JSON.parse(response.content)

    assistant_message = save_answer(answer)
    broadcast_answer(assistant_message, answer["choices"])
  rescue JSON::ParserError, RubyLLM::Error
    broadcast_error
  end

  private

  def instructions
    category = Place::CATEGORIES[@visit.place.category] || @visit.place.category
    "#{SYSTEM_PROMPT}\nThe shop: #{@visit.place.name} (#{category}). #{@visit.place.description}"
  end

  def build_conversation_history
    @ruby_llm_chat.add_message(role: "user", content: "(The customer comes to you.)")
    @visit.messages.prep.order(:id).each do |message|
      @ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end

  def broadcast_remove_typing
    Turbo::StreamsChannel.broadcast_remove_to([@visit, :practice_chat], target: "practice-typing")
  end

  def save_answer(answer)
    @visit.update(prep: { "choices" => answer["choices"] })
    Message.create(role: "assistant", content: answer["staff_japanese"],
                   translation: answer["staff_english"], purpose: :prep, visit: @visit)
  end

  def broadcast_answer(assistant_message, choices)
    broadcast_remove_typing
    Turbo::StreamsChannel.broadcast_append_to(
      [@visit, :practice_chat], target: "practice-messages",
                                partial: "messages/message", locals: { message: assistant_message }
    )
    Turbo::StreamsChannel.broadcast_update_to(
      [@visit, :practice_chat], target: "practice-choices",
                                partial: "messages/choices", locals: { visit: @visit, choices: choices }
    )
  end

  def broadcast_error
    broadcast_remove_typing
    Turbo::StreamsChannel.broadcast_update_to(
      [@visit, :practice_chat], target: "practice-choices",
                                html: "<p>The AI couldn't answer. Please reload the page and try again.</p>"
    )
  end
end
