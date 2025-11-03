# 📄 File: app/controllers/settings_controller.rb
class SettingsController < ApplicationController
  def set_currency
    session[:currency] = params[:currency]
    redirect_back fallback_location: root_path, notice: "Currency set to #{params[:currency]}"
  end
end
