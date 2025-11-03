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

  # 💱 Display price in correct currency
  def display_price(price, user: nil)
    return "Price on request" unless price.present?

    exchange_rate = 130.0

    # ✅ Default to KES unless overridden
    currency = session[:currency] || (
      case session[:payment_method]
      when "mpesa", "paystack"
        "KES"
      when "paypal"
        "USD"
      else
        user_country == "kenya" ? "KES" : "USD"
      end
    )

    if currency == "KES"
      number_to_currency(price * exchange_rate, unit: "KES ")
    else
      number_to_currency(price, unit: "$")
    end
  end
end
