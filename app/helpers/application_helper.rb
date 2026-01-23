# 📄 File: app/helpers/application_helper.rb
module ApplicationHelper
  # ⭐ Render star ratings (full, half, empty)
  def render_stars(rating, max_stars = 5)
    rating = rating.to_i
    full_star  = content_tag(:i, "", class: "bi bi-star-fill text-warning")
    empty_star = content_tag(:i, "", class: "bi bi-star text-muted")

    (full_star * rating).html_safe + (empty_star * (max_stars - rating)).html_safe
  end

  # 🌍 Cache user's country to avoid repeated GeoIP lookups
  def user_country
    session[:user_country] ||= request.location&.country.to_s.downcase.presence || "unknown"
  end

  def display_price(price)
    return "Price on request" unless price.present?

    # Default currency = KES
    currency = session[:currency] || "KES"

    case currency
    when "KES"
      # Stored in KES, so no conversion needed
      number_to_currency(price, unit: "KES ")
    when "USD"
      # Convert from KES → USD
      usd_amount = ExchangeRateService.convert(price, from: "KES", to: "USD") rescue price
      number_to_currency(usd_amount, unit: "$")
    else
      # Fallback: show KES
      number_to_currency(price, unit: "KES ")
    end
  end

  # 💰 Display price with psychological pricing applied
  def display_price_with_psychology(product)
    base_price = product.price.to_f
    return display_price(base_price) unless product.price_ending.present?

    # Remove last 2 digits and apply psychological ending
    # e.g., 1200 with "99" ending → 1199
    base_without_ending = (base_price / 100).floor * 100
    psychological_price = base_without_ending + product.price_ending.to_i
    
    display_price(psychological_price)
  end

  # 📊 Calculate profit for product
  def calculate_profit(product)
    return nil unless product.cost_price&.positive?
    (product.price.to_f - product.cost_price.to_f).round(2)
  end

  # 📊 Calculate profit percentage
  def calculate_profit_percent(product)
    return nil unless product.cost_price&.positive?
    ((product.price.to_f - product.cost_price.to_f) / product.cost_price.to_f * 100).round(2)
  end
end
