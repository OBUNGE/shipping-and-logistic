# 📄 File: app/helpers/application_helper.rb
module ApplicationHelper
  # ⭐ Render star ratings (full, half, empty)
  def render_stars(rating)
    full_stars  = rating.floor
    half_star   = (rating - full_stars >= 0.5) ? 1 : 0
    empty_stars = 5 - full_stars - half_star

    stars_html = ""
    full_stars.times  { stars_html += '<i class="bi bi-star-fill text-warning"></i>' }
    half_star.times   { stars_html += '<i class="bi bi-star-half text-warning"></i>' }
    empty_stars.times { stars_html += '<i class="bi bi-star text-muted"></i>' }

    stars_html.html_safe
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
end
