# 📄 File: app/controllers/currencies_controller.rb
class CurrenciesController < ApplicationController
  def set
    # Only allow KES or USD
    if %w[KES USD].include?(params[:currency])
      session[:currency] = params[:currency]
      flash[:notice] = "Currency switched to #{session[:currency]}"
    else
      flash[:alert] = "Invalid currency selection"
    end

    # Redirect back to the previous page, or home if none
    redirect_back(fallback_location: root_path)
  end
end
