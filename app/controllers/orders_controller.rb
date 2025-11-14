class OrdersController < ApplicationController
  # Allow guest checkout (no login required for new/create/pay/receipt)
  before_action :authenticate_user!, except: [:new, :create, :pay, :receipt]
  before_action :set_product, only: [:new, :create], if: -> { params[:product_id].present? }
  before_action :set_order, only: [:show, :receipt, :pay]

  def index
    @orders = (current_user.orders_as_buyer + current_user.orders_as_seller).uniq
  end

  def show; end

  def new
    if params[:product_id].present?
      @product = Product.find(params[:product_id])
      @order   = user_signed_in? ? current_user.orders_as_buyer.new : Order.new
    else
      if session[:cart].blank?
        redirect_to cart_path, alert: "Your cart is empty." and return
      end

      @cart_items = session[:cart].map do |item|
        product = Product.find(item["product_id"])
        variant = item["variant_id"].present? ? Variant.find_by(id: item["variant_id"]) : nil
        final_price = product.price + (variant&.price_modifier || 0)

        {
          product:    product,
          variant:    variant,
          quantity:   item["quantity"].to_i,
          unit_price: final_price,
          subtotal:   final_price * item["quantity"].to_i,
          shipping:   (product.shipping_cost || 0) * item["quantity"].to_i
        }
      end

      @order = user_signed_in? ? current_user.orders_as_buyer.new : Order.new
    end
  end

  def create
    @order      = user_signed_in? ? current_user.orders_as_buyer.build(order_params) : Order.new(order_params)
    provider    = order_params[:provider] || "mpesa"
    phone_number = order_params[:phone_number].presence || current_user&.phone
    email       = order_params[:email].presence || current_user&.email

    if params[:product_id].present?
      product  = Product.find(params[:product_id])
      variant  = params[:variant_id].present? ? Variant.find_by(id: params[:variant_id]) : nil
      quantity = params[:quantity].to_i.nonzero? || 1

      if quantity > product.stock
        redirect_to product_path(product), alert: "Sorry, only #{product.stock} units available." and return
      end

      ActiveRecord::Base.transaction do
        build_order_items(@order, product, variant, quantity)
        @order.seller = product.seller
        @order.status = :pending
        @order.save!
        decrement_stock!(@order)
      end

      notify_seller(@order)
      handle_payment(@order, provider, phone_number, email)

    else
      # Cart checkout (split by seller)
      grouped_items = (session[:cart] || []).group_by { |item| Product.find(item["product_id"]).seller.id }

      orders = []
      ActiveRecord::Base.transaction do
        grouped_items.each do |seller_id, items|
          order = user_signed_in? ? current_user.orders_as_buyer.build(order_params.merge(seller_id: seller_id, status: :pending)) :
                                    Order.new(order_params.merge(seller_id: seller_id, status: :pending))

          items.each do |item|
            product       = Product.find(item["product_id"])
            variant       = item["variant_id"].present? ? Variant.find_by(id: item["variant_id"]) : nil
            requested_qty = item["quantity"].to_i

            if requested_qty > product.stock
              redirect_to cart_path, alert: "Sorry, only #{product.stock} units of #{product.title} are available." and return
            end

            build_order_items(order, product, variant, requested_qty)
          end

          order.total = order.order_items.sum { |oi| oi.subtotal + (oi.shipping || 0) }
          order.save!
          decrement_stock!(order)
          notify_seller(order)
          orders << order
        end
      end

      session[:cart] = []
      handle_payment(orders.first, provider, phone_number, email)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("⚠️ Order Creation Failed: #{e.record.errors.full_messages.join(', ')}")
    redirect_to new_order_path(product_id: params[:product_id]),
                alert: "Failed to create order: #{e.record.errors.full_messages.join(', ')}"
  end

  def receipt
    order = Order.find(params[:id])
    latest_payment = order.payments.last

    unless latest_payment&.status == "paid"
      redirect_to order, alert: "Receipt is only available after payment." and return
    end

    pdf = ReceiptGenerator.new(order, latest_payment, Time.current).generate
    send_data pdf,
              filename: "receipt_order_#{order.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  # Explicit pay endpoint (if used)
  def pay
    # set_order already loaded via before_action
    phone_number = params[:phone_number].presence || current_user&.phone

    result = MpesaStkPushService.new(
      order: @order,
      mpesa_phone: phone_number, # service still expects mpesa_phone param
      amount: @order.total,
      account_reference: "Order_#{@order.id}",
      description: "Payment for Order #{@order.id}",
      callback_url: mpesa_callback_url(
        order_id: @order.id,
        host: ENV["APP_HOST"] || "https://shipping-and-logistic-wuo1.onrender.com"
      )
    ).call

    respond_to do |format|
      if result.is_a?(Hash) && result[:error]
        format.html { redirect_to order_path(@order), alert: result[:error] }
        format.json { render json: result, status: :unprocessable_entity }
      else
        format.html { redirect_to order_path(@order), notice: "STK Push initiated. Check your phone to complete payment." }
        format.json { render json: result, status: :ok }
      end
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_order
    @order = Order.find(params[:id])

    if user_signed_in?
      unless @order.buyer == current_user || @order.seller == current_user
        redirect_to root_path, alert: "You are not authorized to view this order."
      end
    else
      if @order.buyer.present?
        redirect_to root_path, alert: "You are not authorized to view this order."
      elsif params[:email].present? && @order.email != params[:email]
        redirect_to root_path, alert: "You are not authorized to view this order."
      end
    end
  end

  def notify_seller(order)
    Notification.create!(user: order.seller, message: "New order placed", read: false)
    OrderMailer.seller_notification(order.id).deliver_later
  end

  def decrement_stock!(order)
    order.order_items.each do |item|
      product = item.product
      product.update!(stock: product.stock - item.quantity)
    end
  end

  def build_order_items(order, product, variant, quantity)
    base_price = product.price + (variant&.price_modifier || 0)

    subtotal = ExchangeRateService.convert(
      base_price * quantity,
      from: product.currency,
      to: order.currency
    )

    shipping = (product.shipping_cost || 0) * quantity

    order.order_items.build(
      product:  product,
      variant:  variant,
      quantity: quantity,
      subtotal: subtotal,
      shipping: shipping
    )

    order.total = order.order_items.sum { |oi| oi.subtotal + (oi.shipping || 0) }
  end

  def order_params
    params.require(:order).permit(
      :currency, :provider, :phone_number, :email, :contact_number,
      :first_name, :last_name, :alternate_contact,
      :city, :county, :country, :region, :address, :delivery_notes
    )
  end

  def handle_payment(order, provider, phone_number, email)
    result = PaymentService.process(
      order,
      provider: provider,
      phone_number: phone_number,
      email: email,
      currency: order.currency,
      return_url: order_url(order),
      callback_url: mpesa_callback_url(order_id: order.id,
                                       host: ENV["APP_HOST"] || "shipping-and-logistic-wuo1.onrender.com")
    )

    respond_to do |format|
      if result.is_a?(Hash) && result[:redirect_url]
        format.html         { redirect_to result[:redirect_url], allow_other_host: true }
        format.turbo_stream { redirect_to result[:redirect_url], allow_other_host: true }
      elsif result.is_a?(Hash) && result[:error]
        format.html         { redirect_to order_path(order), alert: result[:error] }
        format.turbo_stream { redirect_to order_path(order), alert: result[:error] }
      else
        format.html         { redirect_to order_path(order), notice: "Order created successfully. Please proceed to payment." }
        format.turbo_stream { redirect_to order_path(order), notice: "Order created successfully. Please proceed to payment." }
      end
    end
  end
end