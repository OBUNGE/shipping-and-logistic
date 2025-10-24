class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_current_user

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :company_name, :phone, roles: []])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :company_name, :phone, roles: []])
  end

  private

  def set_current_user
    Current.user = current_user
  end
end
