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

  # 💱 Display price in correct currency (KES default, USD optional)
  def display_price(price, currency: "KES")
    return "Price on request" unless price.present?

    if currency == "KES"
      kes_amount = ExchangeRateService.convert(price, from: "USD", to: "KES") rescue price
      usd_amount = ExchangeRateService.convert(kes_amount, from: "KES", to: "USD") rescue nil

      output = number_to_currency(kes_amount, unit: "KES ")
      output += " <span class='text-muted small'>(≈ #{number_to_currency(usd_amount, unit: 'USD ')})</span>" if usd_amount
      output.html_safe
    else
      usd_amount = price
      kes_amount = ExchangeRateService.convert(usd_amount, from: "USD", to: "KES") rescue nil

      output = number_to_currency(usd_amount, unit: "USD ")
      output += " <span class='text-muted small'>(≈ #{number_to_currency(kes_amount, unit: 'KES ')})</span>" if kes_amount
      output.html_safe
    end
  end
end
