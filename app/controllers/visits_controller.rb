class VisitsController < ApplicationController
  before_action :set_visit

  # Post-visit summary: XP earned, level progress, phrases used.
  def show
  end

  # "How did it go?" form, filled in after coming back from the place.
  def review
    redirect_to visit_path(@visit), notice: "You've already reviewed this visit." if @visit.reviewed?
  end

  def update
    levels_gained = @visit.complete_review!(
      self_rating: review_params[:self_rating].to_i,
      confidence: review_params[:confidence].to_i,
      used_phrase_ids: used_phrase_ids
    )
    flash[:levels_gained] = levels_gained if levels_gained.positive?
    redirect_to visit_path(@visit)
  rescue ActiveRecord::RecordInvalid
    render :review, status: :unprocessable_entity
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
