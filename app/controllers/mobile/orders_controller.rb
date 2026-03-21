module Mobile
  class OrdersController < ApplicationController
    before_action :authenticate_user!

    def new
      @cart_items = session[:cart] || {}
      @products = Product.find(@cart_items.keys) rescue []
      @order = Order.new
    end

    def create
      cart_items = session[:cart] || {}
      return redirect_to mobile_home_index_path, alert: 'Cart is empty' if cart_items.empty?

      @order = Order.new(order_params)
      @order.user = current_user
      
      if @order.save
        # Create order items from cart
        Product.find(cart_items.keys).each do |product|
          @order.order_items.create(
            product: product,
            quantity: cart_items[product.id.to_s].to_i,
            unit_price: product.price
          ) if @order.order_items.respond_to?(:create)
        end
        
        session[:cart] = nil
        redirect_to mobile_order_confirmation_path(@order), notice: 'Order placed successfully!'
      else
        render :new
      end
    end

    def confirmation
      @order = Order.find(params[:order_id] || params[:id])
      @order_items = @order.order_items rescue []
    end

    private

    def order_params
      params.require(:order).permit(:email, :phone, :address, :city, :zip_code, :payment_method).merge(
        email: params.dig(:order, :email) || current_user.email,
        phone: params.dig(:order, :phone)
      )
    end
  end
end
