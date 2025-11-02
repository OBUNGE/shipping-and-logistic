class CartsController < ApplicationController
  def show
    @cart_items = (session[:cart] || []).map do |item|
      begin
        product = Product.find(item["product_id"])
      rescue ActiveRecord::RecordNotFound
        next
      end

      variant_id = item["variant_id"].presence
      variant = variant_id ? Variant.find_by(id: variant_id) : nil
      quantity = item["quantity"].to_i.nonzero? || 1
      final_price = product.price + (variant&.price_modifier || 0)

      {
        product: product,
        variant: variant,
        quantity: quantity,
        unit_price: final_price,
        subtotal: final_price * quantity,
        shipping: (product.shipping_cost || 0) * quantity
      }
    end.compact
  end

  def add
    session[:cart] ||= []
    product_id = params[:product_id].to_i

    if params[:variants].present?
      # Multiple variants case (hash of {variant_id => qty})
      params[:variants].each do |variant_id, qty|
        quantity = qty.to_i.nonzero? || 1
        next if quantity <= 0

        add_or_update_cart_item(product_id, variant_id.to_i, quantity)
      end
    else
      # Simple product (no variants or single variant)
      variant_id = params[:variant_id].to_i if params[:variant_id].present?
      quantity   = params[:quantity].to_i.nonzero? || 1
      add_or_update_cart_item(product_id, variant_id, quantity)
    end

    Rails.logger.info "🛒 Cart After Add: #{session[:cart].inspect}"

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path, notice: "Product(s) added to cart." }
    end
  end

  def remove
    product_id = params[:product_id].to_i
    variant_id = params[:variant_id].to_i if params[:variant_id].present?

    session[:cart]&.reject! do |i|
      i["product_id"] == product_id && i["variant_id"].to_i == variant_id.to_i
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
    variant_id   = params[:variant_id].to_i if params[:variant_id].present?
    new_quantity = params[:quantity].to_i.nonzero? || 1

    session[:cart]&.each do |item|
      if item["product_id"] == product_id && item["variant_id"].to_i == variant_id.to_i
        item["quantity"] = new_quantity
        break
      end
    end

    Rails.logger.info "🛒 Cart After Update: #{session[:cart].inspect}"
    redirect_to cart_path, notice: "Quantity updated."
  end

  private

  def add_or_update_cart_item(product_id, variant_id, quantity)
    return if quantity <= 0
    variant_id ||= 0

    existing = session[:cart].find do |i|
      i["product_id"] == product_id && i["variant_id"].to_i == variant_id
    end

    if existing
      existing["quantity"] += quantity
    else
      session[:cart] << {
        "product_id" => product_id,
        "variant_id" => variant_id,
        "quantity"   => quantity
      }
    end
  end
end
