class OrdersController < ApplicationController
  # 🔓 Guests can shop freely — only restrict account history
  before_action :authenticate_user!, only: [:index]
  before_action :set_product, only: [:new, :create], if: -> { params[:product_id].present? }
  before_action :set_order, only: [:show, :receipt, :pay]

  def index
    # Only available for signed-in users
    @orders = (current_user.orders_as_buyer + current_user.orders_as_seller).uniq
  end

def show
  # Find the order first
  @order = Order.find_by(id: params[:id])

  if @order.nil?
    redirect_to root_path, alert: "Order not found"
    return
  end

  # Guests can view orders if they have the guest_token in the URL
  if @order.guest_token.present? && params[:token] == @order.guest_token
    render :show

  # Signed-in users can view if they are buyer or seller
  elsif user_signed_in? && (@order.buyer == current_user || @order.seller == current_user)
    render :show

  else
    redirect_to root_path, alert: "You don’t have access to this order."
  end
end


  def new
    if params[:product_id].present?
      # --- Single product checkout ---
      @product = Product.find(params[:product_id])
      @order   = user_signed_in? ? current_user.orders_as_buyer.new : Order.new(currency: "KES")

      destination = current_user&.city.presence || "Nairobi"
      calculator  = ShippingCalculator.new(strategy: :weight_based, destination: destination)
      @shipping_total = calculator.calculate([{ product: @product, variants: [], quantity: 1 }])

    else
      # --- Cart checkout ---
      if session[:cart].blank?
        redirect_to cart_path, alert: "Your cart is empty." and return
      end

      order_currency = "KES"

      @cart_items = session[:cart].map do |item|
        product     = Product.find(item["product_id"])
        variant_ids = Array(item["variant_ids"]).map(&:to_i)
        variants    = Variant.where(id: variant_ids)
        quantity    = item["quantity"].to_i.nonzero? || 1

        effective   = product.discount&.active? ? product.discounted_price : product.price
        effective  += variants.sum { |v| v.price_modifier.to_f }

        unit_price  = ExchangeRateService.convert(effective, from: product.currency, to: order_currency)
        subtotal    = unit_price * quantity

        {
          product:    product,
          variants:   variants,
          quantity:   quantity,
          unit_price: unit_price,
          subtotal:   subtotal
        }
      end

      destination = current_user&.city.presence || "Nairobi"
      calculator  = ShippingCalculator.new(strategy: :weight_based, destination: destination)
      @shipping_total = calculator.calculate(@cart_items)

      @order = user_signed_in? ? current_user.orders_as_buyer.new(currency: order_currency) : Order.new(currency: order_currency)
    end
  end
  
  
def create
  @order = user_signed_in? ? current_user.orders_as_buyer.build(order_params) : Order.new(order_params)
  @order.currency ||= "KES"
  @order.guest_token ||= SecureRandom.hex(10) unless user_signed_in?

  provider       = order_params[:provider] || "mpesa"
  phone_number   = order_params[:phone_number].presence || current_user&.phone
  contact_number = order_params[:contact_number].presence || current_user&.phone
  email          = order_params[:email].presence || current_user&.email

  Rails.logger.info("🛒 Starting order creation: provider=#{provider}, currency=#{@order.currency}, email=#{email}")

  if params[:product_slug].present?
    # --- Single product checkout ---
    product     = Product.find_by!(slug: params[:product_slug])
    variant_ids = Array(params[:order][:variant_ids] || params[:order][:variant_id]).map(&:to_i)
    variants    = Variant.where(id: variant_ids)
    quantity    = params[:order][:quantity].to_i.nonzero? || 1

    if quantity > product.stock
      redirect_to product_path(product), alert: "Sorry, only #{product.stock} units available." and return
    end

    ActiveRecord::Base.transaction do
      build_order_item!(@order, product, variants, quantity)
      @order.seller = product.seller
      @order.status = :pending

      subtotal = @order.order_items.sum(&:subtotal)
      calculator = ShippingCalculator.new(
        strategy:    :weight_based,
        destination: order_params[:city],
        country:     order_params[:country],
        county:      order_params[:county]
      )
      @order.shipping_total = calculator.calculate([{ product: product, variants: variants, quantity: quantity }])
      @order.subtotal = subtotal
      @order.total    = subtotal + @order.shipping_total

      @order.update!(provider: provider, payment_method: provider)
      @order.save!
      decrement_stock!(@order)
    end

    notify_seller(@order)

    handle_payment(@order, provider, phone_number, email)
    return  # prevent double redirect

  else
    # --- Cart checkout ---
    if session[:cart].blank?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end

    grouped_items = session[:cart].group_by { |item| Product.find(item["product_id"]).seller.id }
    orders = []

    ActiveRecord::Base.transaction do
      grouped_items.each do |seller_id, items|
        order = user_signed_in? ? current_user.orders_as_buyer.build(order_params.merge(seller_id: seller_id, status: :pending)) :
                                  Order.new(order_params.merge(seller_id: seller_id, status: :pending))

        order.currency ||= "KES"
        order.guest_token ||= SecureRandom.hex(10) unless user_signed_in?

        items.each do |item|
          product       = Product.find(item["product_id"])
          variant_ids   = Array(item["variant_ids"] || item["variant_id"]).map(&:to_i)
          variants      = Variant.where(id: variant_ids)
          requested_qty = item["quantity"].to_i.nonzero? || 1

          if requested_qty > product.stock
            redirect_to cart_path, alert: "Sorry, only #{product.stock} units of #{product.title} are available." and return
          end

          build_order_item!(order, product, variants, requested_qty)
        end

        subtotal = order.order_items.sum(&:subtotal)
        calculator = ShippingCalculator.new(
          strategy:    :weight_based,
          destination: order_params[:city],
          country:     order_params[:country],
          county:      order_params[:county]
        )
        order.shipping_total = calculator.calculate(items.map do |i|
          {
            product:  Product.find(i["product_id"]),
            variants: Variant.where(id: Array(i["variant_ids"] || i["variant_id"]).map(&:to_i)),
            quantity: i["quantity"].to_i
          }
        end)
        order.subtotal = subtotal
        order.total    = subtotal + order.shipping_total

        order.update!(provider: provider, payment_method: provider)
        order.save!
        decrement_stock!(order)
        notify_seller(order)
        orders << order
      end
    end

    session[:cart] = []

    handle_payment(orders.first, provider, phone_number, email)
    return  # prevent double redirect
  end
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error("⚠️ Order Creation Failed: #{e.record.errors.full_messages.join(', ')}")
  redirect_to new_order_path(product_slug: params[:product_slug]),
              alert: "Failed to create order: #{e.record.errors.full_messages.join(', ')}"
end

  def receipt
    order = Order.find(params[:id])
    latest_payment = order.payments.last

    unless latest_payment&.status == "paid"
      redirect_to order, alert: "Receipt is only available after payment." and return
    end

    # ✅ Allow guests via token
    if order.guest_token.present? && params[:token] == order.guest_token
      pdf = ReceiptGenerator.new(order, latest_payment, Time.current).generate
      send_data pdf,
                filename: "receipt_order_#{order.id}.pdf",
                type: "application/pdf",
                disposition: "inline"
    elsif user_signed_in? && (order.buyer == current_user || order.seller == current_user)
      pdf = ReceiptGenerator.new(order, latest_payment, Time.current).generate
      send_data pdf,
                filename: "receipt_order_#{order.id}.pdf",
                type: "application/pdf",
                disposition: "inline"
    else
      redirect_to root_path, alert: "You don’t have access to this receipt."
    end
  end

  def pay
    phone_number = params[:phone_number].presence || current_user&.phone

    result = MpesaStkPushService.new(
      order: @order,
      phone_number: phone_number,
      amount: @order.total,
      account_reference: "Order_#{@order.id}",
      description: "Payment for Order #{@order.id}",
      callback_url: mpesa_callback_url(order_id: @order.id, host: ENV["APP_HOST"] || "tajaone.app")
    ).call

    respond_to do |format|
      if result.is_a?(Hash) && result[:error]
        format.html { redirect_to order_path(@order), alert: result[:error] }
        format.json { render json: { error: result[:error] }, status: :unprocessable_entity }
      elsif result.is_a?(Hash) && result[:checkout_url]
        format.html { redirect_to result[:checkout_url], allow_other_host: true }
        format.json { render json: { checkout_url: result[:checkout_url] } }
      else
        format.html { redirect_to order_path(@order), notice: "Please complete the payment on your phone." }
        format.json { render json: { message: "Please complete the payment on your phone." } }
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

def build_order_item!(order, product, variants, quantity)
  quantity = quantity.to_i.nonzero? || 1
  variants = Array(variants).compact

  effective = product.effective_price(variants.presence || nil) || product.price
  unit_price_converted = ExchangeRateService.convert(effective, from: product.currency, to: order.currency)
  subtotal = unit_price_converted.to_f * quantity

  calculator = ShippingCalculator.new(
    strategy:    :weight_based,
    destination: order.city,
    country:     order.country,
    county:      order.county
  )
  item_shipping_total = calculator.calculate([{ product: product, variants: variants, quantity: quantity }])
  per_item_shipping = item_shipping_total.to_f / quantity

  order_item = order.order_items.build(
    product:    product,
    quantity:   quantity,
    unit_price: unit_price_converted.to_f,
    subtotal:   subtotal,
    shipping:   per_item_shipping
  )

  variants.each { |v| order_item.order_item_variants.build(variant: v) }

  Rails.logger.info("OrderItem valid?: #{order_item.valid?}")
  Rails.logger.info("OrderItem errors: #{order_item.errors.full_messages}") unless order_item.valid?

  order_item
end


def order_params
  params.require(:order).permit(
    :buyer_id,
    :seller_id,
    :currency,
    :provider,
    :payment_method,
    :phone_number,
    :email,
    :contact_number,
    :first_name,
    :last_name,
    :alternate_contact,
    :city,
    :county,
    :country,
    :region,
    :address,
    :delivery_notes,
    :subtotal,
    :shipping_total,
    :status
  )
end

def handle_payment(order, provider, phone_number, email)
  unless order.present?
    Rails.logger.error("⚠️ handle_payment called with nil order")
    redirect_to root_path, alert: "Order not found" and return
  end

  # Persist chosen provider/payment method
  order.update!(provider: provider, payment_method: provider)

  Rails.logger.info("💳 Initiating payment: order_id=#{order.id}, provider=#{provider}, currency=#{order.currency}")

  if provider == "pod"
    order.payments.create!(
      provider: "POD",
      amount: order.total,
      currency: order.currency,
      status: :pending
    )
    redirect_to order_path(order), notice: "Order placed with Pay on Delivery. We’ll contact you to confirm delivery in Nairobi."
    return
  end

  result = PaymentService.process(
    order,
    provider: provider,
    phone_number: phone_number,
    email: email,
    currency: order.currency,
    return_url: order_url(order),
    callback_url: mpesa_callback_url(
      order_id: order.id,
      host: ENV["APP_HOST"] || "tajaone.app"
    )
  )

  respond_to do |format|
    if result.is_a?(Hash) && result[:redirect_url]
      Rails.logger.info("✅ Payment redirect for order #{order.id}: #{result[:redirect_url]}")
      format.html         { redirect_to result[:redirect_url], allow_other_host: true }
      format.turbo_stream { redirect_to result[:redirect_url], allow_other_host: true }
    elsif result.is_a?(Hash) && result[:error]
      Rails.logger.error("❌ Payment error for order #{order.id}: #{result[:error]}")
      format.html         { redirect_to order_path(order), alert: result[:error] }
      format.turbo_stream { redirect_to order_path(order), alert: result[:error] }
    else
      Rails.logger.info("ℹ️ Payment fallback for order #{order.id}")
      format.html         { redirect_to order_path(order), notice: "Order created successfully. Please proceed to payment." }
      format.turbo_stream { redirect_to order_path(order), notice: "Order created successfully. Please proceed to payment." }
    end
  end
end


end
