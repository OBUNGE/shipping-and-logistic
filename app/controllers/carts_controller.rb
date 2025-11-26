class CartsController < ApplicationController
def show
  @cart_items = (session[:cart] || []).map do |item|
    begin
      product = Product.find(item["product_id"])
    rescue ActiveRecord::RecordNotFound
      next
    end

    variant_ids = Array(item["variant_ids"]).map(&:to_i)
    variants    = Variant.where(id: variant_ids)
    quantity    = item["quantity"].to_i.nonzero? || 1

    unit_price = product.discount&.active? ? product.discounted_price : product.price
    unit_price += variants.sum { |v| v.price_modifier.to_f }

    {
      product:  product,
      variants: variants,
      quantity: quantity,
      unit_price: unit_price,
      subtotal:  unit_price * quantity
    }
  end.compact

  # ✅ Fix: fallback to Nairobi if user.city not defined
  destination = current_user&.city.presence || "Nairobi"
  calculator  = ShippingCalculator.new(strategy: :weight_based, destination: destination)

  @shipping_total = calculator.calculate(@cart_items)
  @subtotal       = @cart_items.sum { |i| i[:subtotal] }
  @grand_total    = @subtotal + @shipping_total
end

  def add
    session[:cart] ||= []
    product_id = params[:product_id].to_i
    quantity   = params[:quantity].to_i.nonzero? || 1

    # ✅ Collect variant IDs from either unified hash or separate keys
    variant_ids = []
    if params[:variants].present?
      # Preferred case: { "Color" => "236", "Storage" => "241" }
      variant_ids = params[:variants].values.map(&:to_i)
    else
      # Fallback case: separate keys like color_variant_id, storage_variant_id
      variant_ids << params[:color_variant_id].to_i if params[:color_variant_id].present?
      variant_ids << params[:storage_variant_id].to_i if params[:storage_variant_id].present?
      # Add more here if you introduce other variant groups (e.g. warranty_variant_id)
    end

    add_or_update_cart_item(product_id, variant_ids, quantity)

    Rails.logger.info "🛒 Cart After Add: #{session[:cart].inspect}"

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path, notice: "Product(s) added to cart." }
    end
  end

  def remove
    product_id  = params[:product_id].to_i
    variant_ids = params[:variant_ids].present? ? Array(params[:variant_ids]).map(&:to_i) : []

    session[:cart]&.reject! do |i|
      i["product_id"] == product_id && Array(i["variant_ids"]).map(&:to_i) == variant_ids
    end

    Rails.logger.info "🛒 Cart After Remove: #{session[:cart].inspect}"
    redirect_to cart_path, notice: "Product removed."
  end

  def clear
    session[:cart] = []
    Rails.logger.info "🛒 Cart Cleared"
    redirect_to cart_path, notice: "Cart cleared."
  end

  def update
    product_id   = params[:product_id].to_i
    variant_ids  = params[:variant_ids].present? ? Array(params[:variant_ids]).map(&:to_i) : []
    new_quantity = params[:quantity].to_i.nonzero? || 1

    session[:cart]&.each do |item|
      if item["product_id"] == product_id && Array(item["variant_ids"]).map(&:to_i) == variant_ids
        item["quantity"] = new_quantity
        break
      end
    end

    Rails.logger.info "🛒 Cart After Update: #{session[:cart].inspect}"
    redirect_to cart_path, notice: "Quantity updated."
  end

  private

  def add_or_update_cart_item(product_id, variant_ids, quantity)
    return if quantity <= 0

    existing = session[:cart].find do |i|
      i["product_id"] == product_id && Array(i["variant_ids"]).map(&:to_i) == variant_ids
    end

    if existing
      existing["quantity"] += quantity
    else
      session[:cart] << {
        "product_id"  => product_id,
        "variant_ids" => variant_ids,
        "quantity"    => quantity
      }
    end
  end
end
