module Mobile
  class CartsController < ApplicationController
    def show
      # Using session-based cart for simplicity
      @cart_items = session[:cart] || {}
      @products = Product.find(@cart_items.keys).index_by(&:id) rescue {}
    end

    def add_item
      session[:cart] ||= {}
      product_id = params[:product_id].to_i
      quantity = (params[:quantity] || 1).to_i
      
      session[:cart][product_id.to_s] = (session[:cart][product_id.to_s] || 0) + quantity
      session[:cart].delete_if { |_, v| v <= 0 }
      
      redirect_to mobile_cart_path, notice: 'Item added to cart'
    end

    def remove_item
      session[:cart] ||= {}
      session[:cart].delete(params[:product_id].to_s)
      redirect_to mobile_cart_path, notice: 'Item removed from cart'
    end
  end
end
