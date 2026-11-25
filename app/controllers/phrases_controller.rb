class PhrasesController < ApplicationController
  before_action :set_visit

  # "Add" on a suggested staff phrase: saves it as a private "heard" phrase on
  # the visit, which puts it on the user's study list. Earns no XP.
  def create
    @phrase = build_phrase
    saved = @phrase.save
    @suggestion_index = Integer(params[:suggestion], exception: false)

    respond_to do |format|
      format.turbo_stream { render :create, status: saved ? :ok : :unprocessable_entity }
      format.html do
        redirect_to review_visit_path(@visit), alert: (@phrase.errors.full_messages.to_sentence unless saved)
      end
    end
  end

  private

  def set_visit
    @visit = current_user.visits.find(params[:visit_id])
  end

  # Adding a phrase already on this visit is a no-op (exact Japanese match)
  def build_phrase
    phrase = @visit.phrases.find_or_initialize_by(japanese: phrase_params[:japanese].to_s.strip)
    return phrase if phrase.persisted?

    phrase.assign_attributes(source: :heard, romaji: phrase_params[:romaji], english: phrase_params[:english])
    phrase
  end

  def phrase_params
    params.expect(phrase: %i[japanese romaji english])
  end
end
