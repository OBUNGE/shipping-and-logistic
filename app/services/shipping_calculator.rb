class ShippingCalculator
  FREE_SHIPPING_THRESHOLDS = {
    nairobi: 5000,   # KES threshold for Nairobi zone
    upcountry: 7000, # KES threshold for other Kenyan counties
    international: 10000 # KES threshold for outside Kenya
  }.freeze

  def initialize(strategy: :weight_based, destination: "Nairobi", country: "Kenya", county: nil)
    @strategy    = strategy
    @destination = destination.to_s.strip
    @country     = country.to_s.strip
    @county      = county.to_s.strip
  end

  # Public entry point
  def calculate(cart_items)
    # ✅ Check free shipping threshold first
    subtotal = cart_items.sum { |item| item[:unit_price].to_f * item[:quantity].to_i }
    return 0 if eligible_for_free_shipping?(subtotal)

    case @strategy
    when :flat_rate
      flat_rate
    when :weight_based
      weight_based(cart_items)
    when :per_item
      per_item(cart_items)
    else
      raise ArgumentError, "Unknown shipping strategy: #{@strategy}"
    end
  end

  private

  # 1️⃣ Flat Rate Shipping
  def flat_rate
    300 # KES flat fee
  end

  # 2️⃣ Weight-Based Shipping
  def weight_based(cart_items)
    base_fee    = 200       # minimum charge
    per_kg_rate = 50        # cost per kg

    zone_multiplier = zone_multiplier_for(@destination, @country, @county)

    total_weight = cart_items.sum do |item|
      item[:product].weight.to_f * item[:quantity].to_i
    end

    (base_fee + (total_weight * per_kg_rate)) * zone_multiplier
  end

  # 3️⃣ Per-Item Shipping
  def per_item(cart_items)
    cart_items.sum do |item|
      (item[:product].shipping_cost || 0) * item[:quantity].to_i
    end
  end

  # 🔑 Zone logic based on destination
  def zone_multiplier_for(city, country, county)
    return 2.0 if country.present? && country.downcase != "kenya"

    city   = city.to_s.downcase
    county = county.to_s.downcase

    if city.include?("nairobi") || county.include?("nairobi")
      1.0 # Nairobi zone
    else
      1.5 # Upcountry (anywhere else in Kenya)
    end
  end

  # ✅ Free shipping eligibility by zone
  def eligible_for_free_shipping?(subtotal)
    if @country.present? && @country.downcase != "kenya"
      subtotal >= FREE_SHIPPING_THRESHOLDS[:international]
    elsif @destination.to_s.downcase.include?("nairobi") || @county.to_s.downcase.include?("nairobi")
      subtotal >= FREE_SHIPPING_THRESHOLDS[:nairobi]
    else
      subtotal >= FREE_SHIPPING_THRESHOLDS[:upcountry]
    end
  end
end
