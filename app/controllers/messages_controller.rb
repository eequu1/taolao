class MessagesController < ApplicationController
  def create
    visit = current_user.visits.find(params[:visit_id])
    visit.messages.prep.create!(role: "user", content: params[:content])
    redirect_to visit_path(visit)
  end
end
