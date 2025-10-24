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

  # 💱 Display price in correct currency
def display_price(price, user: nil)
  return "Price on request" unless price.present?

  exchange_rate = 130.0

  case session[:payment_method]
  when "mpesa", "paystack"
    return number_to_currency(price * exchange_rate, unit: "KES ")
  when "paypal"
    return number_to_currency(price, unit: "$")
  end

  # Default by country (GeoIP only)
  country = request.location&.country
  if country&.downcase == "kenya"
    number_to_currency(price * exchange_rate, unit: "KES ")
  else
    number_to_currency(price, unit: "$")
  end
end

end
