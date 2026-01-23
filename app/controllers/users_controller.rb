class UsersController < ApplicationController
  before_action :authenticate_user!

  # =========================
  # Role Switching
  # =========================
def become_seller
  if current_user.update(account_params)
    if current_user.seller_profile_complete?
      current_user.become_seller!
      redirect_to seller_dashboard_path, notice: "Your storefront has been created!"
    else
      flash.now[:alert] = "Please complete all required details."
      render :new_seller, status: :unprocessable_entity
    end
  else
    flash.now[:alert] = "There was a problem saving your details."
    render :new_seller, status: :unprocessable_entity
  end
end



  def become_buyer
    current_user.become_buyer!
    redirect_back fallback_location: root_path, notice: "You are now a buyer!"
  end

  def toggle_role
    current_user.toggle_active_role!
    redirect_back fallback_location: root_path, notice: "Active role switched to #{current_user.active_role}"
  end

  # =========================
  # My Account (Profile)
  # =========================
  def account
    @user = current_user
  end

  def update_account
    @user = current_user
    if @user.update(account_params)
      redirect_to account_path, notice: "Account updated successfully."
    else
      flash.now[:alert] = "There was a problem updating your account."
      render :account, status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:user).permit(
      :name,
      :email,
      :phone,
      :password,
      :password_confirmation,
      :store_name,
      :store_description,
      :store_logo_url,
      :store_banner_url,
      roles: []
    )
  end
end
