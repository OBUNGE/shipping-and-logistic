class CartsController < ApplicationController
  def show
    @cart_items = (session[:cart] || []).map do |item|
      product = Product.find(item["product_id"])
      variant = item["variant_id"].present? ? Variant.find_by(id: item["variant_id"]) : nil
      final_price = product.price + (variant&.price_modifier || 0)

      {
        product: product,
        variant: variant,
        quantity: item["quantity"].to_i,
        unit_price: final_price,
        subtotal: final_price * item["quantity"].to_i,
        shipping: (product.shipping_cost || 0) * item["quantity"].to_i
      }
    end
  end

  def add
    session[:cart] ||= []
    product_id = params[:product_id].to_i

    if params[:variants].present?
      # Multiple variants case (hash of {variant_id => qty})
      params[:variants].each do |variant_id, qty|
        quantity = qty.to_i
        next if quantity <= 0

        add_or_update_cart_item(product_id, variant_id.to_i, quantity)
      end
    else
      # Simple product (no variants or single variant)
      variant_id = params[:variant_id].to_i if params[:variant_id].present?
      quantity   = params[:quantity].to_i
      add_or_update_cart_item(product_id, variant_id, quantity)
    end

    redirect_to cart_path, notice: "Product(s) added to cart."
  end

  def remove
    product_id = params[:product_id].to_i
    variant_id = params[:variant_id].to_i if params[:variant_id].present?

    session[:cart]&.reject! do |i|
      i["product_id"] == product_id && i["variant_id"].to_i == variant_id.to_i
    end

    redirect_to cart_path, notice: "Product removed."
  end

  def clear
    session[:cart] = []
    redirect_to cart_path, notice: "Cart cleared."
  end

  def update
    product_id   = params[:product_id].to_i
    variant_id   = params[:variant_id].to_i if params[:variant_id].present?
    new_quantity = params[:quantity].to_i

    session[:cart]&.each do |item|
      if item["product_id"] == product_id && item["variant_id"].to_i == variant_id.to_i
        item["quantity"] = new_quantity
        break
      end
    end

    redirect_to cart_path, notice: "Quantity updated."
  end

  private

  def add_or_update_cart_item(product_id, variant_id, quantity)
    return if quantity <= 0

    existing = session[:cart].find do |i|
      i["product_id"] == product_id && i["variant_id"].to_i == variant_id.to_i
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
