class VisitsController < ApplicationController
  before_action :set_visit, except: :create

  def create
    place = Place.find(params[:place_id])
    visit = current_user.visits.active.find_or_create_by!(place: place)
    redirect_to visit_path(visit)
  end

  # Post-visit summary: XP earned, level progress, phrases used and added.
  def show
    # Out at the place: show the listening page instead of the practice chat
    return render :listening if @visit.ready?

    @messages = @visit.messages.prep.order(:id)
    # FAKE for now: the AI will make these later
    @choices = [
      { japanese: "ホットでお願いします。", romaji: "Hotto de onegai shimasu.", english: "Hot, please" },
      { japanese: "アイスでお願いします。", romaji: "Aisu de onegai shimasu.", english: "Iced, please" },
      { japanese: "はい。", romaji: "Hai.", english: "Yes" }
    ]
  end

  # "I'm ready!" on the practice page: off to the place, show page becomes the listening page
  def ready
    @visit.ready! if @visit.active?
    redirect_to visit_path(@visit)
  end

  # "Interaction over" on the listening page
  def complete
    @visit.completed! if @visit.ready?
    redirect_to review_visit_path(@visit)
  end

  # The post-visit page: rating form (or the XP card once submitted),
  # suggested staff phrases, and the "what did you hear?" chat.
  def review
    @messages = @visit.messages.review.order(:id)
  end

  def update
    levels_gained = @visit.complete_review!(
      self_rating: review_params[:self_rating].to_i,
      confidence: review_params[:confidence].to_i,
      used_phrase_ids: used_phrase_ids
    )
    flash[:levels_gained] = levels_gained if levels_gained.positive?
    # Back to the review page, where the form becomes the XP card and the chat stays available
    redirect_to review_visit_path(@visit)
  rescue ActiveRecord::RecordInvalid
    @messages = @visit.messages.review.order(:id)
    render :review, status: :unprocessable_entity
  end

  # Turbo Frame content for the review page; slow (AI call) so it loads after the page
  def phrase_suggestions
    @suggestions = StaffPhraseSuggester.call(@visit.place)
    @added = @visit.phrases.pluck(:japanese)
    render layout: false
  end

  private

  # Scoped to the signed-in user, so other people's visits are a 404.
  def set_visit
    @visit = current_user.visits.find(params[:id])
  end

  # fetch, not require: an empty submission should re-show the form, not 400
  def review_params
    params.fetch(:visit, {}).permit(:self_rating, :confidence, used_phrase_ids: [])
  end

  def used_phrase_ids
    @used_phrase_ids = Array(review_params[:used_phrase_ids]).compact_blank.map(&:to_i)
  end
end
