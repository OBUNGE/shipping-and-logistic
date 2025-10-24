class UsersController < ApplicationController
  before_action :authenticate_user!

  def become_seller
    current_user.become_seller!
    redirect_back fallback_location: root_path, notice: "You are now a seller!"
  end

  def become_buyer
    current_user.become_buyer!
    redirect_back fallback_location: root_path, notice: "You are now a buyer!"
  end

  def toggle_role
    current_user.toggle_active_role!
    redirect_back fallback_location: root_path, notice: "Active role switched to #{current_user.active_role}"
  end
end
