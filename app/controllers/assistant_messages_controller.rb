class AssistantMessagesController < ApplicationController
  def create
    render json: { reply: GoldenlyAssistant.new(params[:message]).reply, safety_note: "Goldenly provides coordination support, not medical advice." }
  end
end
