class MessagesController < ApplicationController
  def create
    @visit = current_user.visits.find(params[:visit_id])
    @message = Message.new(role: "user", content: params[:content], translation: params[:translation],
                           purpose: :prep, visit: @visit)

    if @message.save
      PracticeMessageJob.perform_later(@visit)
      respond_to do |format|
        format.turbo_stream # renders app/views/messages/create.turbo_stream.erb
        format.html { redirect_to visit_path(@visit) }
      end
    else
      redirect_to visit_path(@visit), alert: "Something went wrong."
    end
  end
end
