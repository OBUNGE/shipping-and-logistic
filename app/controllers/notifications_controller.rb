class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.order(created_at: :desc)
    # Mark all as read when viewed
    @notifications.update_all(read: true)
  end
end
