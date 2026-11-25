class PhrasesController < ApplicationController
  before_action :set_visit
  before_action :require_review

  # "Anything you heard but didn't understand?": adds a phrase to a reviewed
  # visit, either picked from the suggestions (heard) or typed in (manual).
  # Earns no XP: XP only comes from the review and from memorizing.
  def create
    @phrase = @visit.phrases.new(phrase_params.merge(source: source))
    saved = @phrase.save

    respond_to do |format|
      # create.turbo_stream.erb appends the phrase, or re-renders the form with errors
      format.turbo_stream { render :create, status: saved ? :ok : :unprocessable_entity }
      format.html do
        redirect_to visit_path(@visit, anchor: "heard"),
                    alert: (@phrase.errors.full_messages.to_sentence unless saved)
      end
    end
  end

  private

  def set_visit
    @visit = current_user.visits.find(params[:visit_id])
  end

  def require_review
    redirect_to visit_path(@visit), alert: "Review your visit first." unless @visit.reviewed?
  end

  def phrase_params
    params.expect(phrase: %i[japanese romaji english])
  end

  # Only "heard" or "manual" can come from the form; prepped phrases belong to the Prep stage
  def source
    params.dig(:phrase, :source) == "heard" ? :heard : :manual
  end
end
