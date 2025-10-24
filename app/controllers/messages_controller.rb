# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    # Show all messages between current_user and another user
    @other_user = User.find(params[:user_id])
    @messages = Message.where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      current_user.id, @other_user.id, @other_user.id, current_user.id
    ).order(:created_at)
  end

  def create
    @message = current_user.sent_messages.build(
      receiver_id: params[:receiver_id],
      content: params[:content]
    )
    if @message.save
      redirect_to messages_path(user_id: params[:receiver_id])
    else
      redirect_back fallback_location: root_path, alert: "Message can't be empty"
    end
  end
end
