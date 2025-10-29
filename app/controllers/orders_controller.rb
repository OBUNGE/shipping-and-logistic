class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:new, :create], if: -> { params[:product_id].present? }
  before_action :set_order, only: [:show, :receipt]

  # === GET /orders ===
  def index
    @orders = (current_user.orders_as_buyer + current_user.orders_as_seller).uniq
  end

  # === GET /orders/:id ===
  def show; end

  # === GET /orders/new ===
  def new
    if params[:product_id].present?
      # Single product checkout
      @order = current_user.orders_as_buyer.new
    else
      # Cart checkout
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
      @order = current_user.orders_as_buyer.new
    end
  end

  # === POST /orders ===
  def create
    phone_number   = params[:phone_number].presence || current_user.phone
    provider       = params[:provider] || "mpesa"
    first_name     = params[:first_name]
    last_name      = params[:last_name]
    address        = params[:delivery_address]
    buyer_currency = params[:currency].presence || "USD"

    if params[:product_id].present?
      # --- Single product checkout ---
      product  = Product.find(params[:product_id])
      variant  = params[:variant_id].present? ? Variant.find_by(id: params[:variant_id]) : nil
      quantity = params[:quantity].to_i.nonzero? || 1

      if quantity > product.stock
        redirect_to product_path(product), alert: "Sorry, only #{product.stock} units available." and return
      end

      order = build_order_for_product(product, variant, quantity, first_name, last_name, address, buyer_currency)

      ActiveRecord::Base.transaction do
        order.save!
        decrement_stock!(order)
      end

      notify_seller(product.seller)
      handle_payment(order, provider, phone_number)

    else
      # --- Cart checkout (grouped by seller) ---
      grouped_items = (session[:cart] || []).group_by do |item|
        Product.find(item["product_id"]).seller.id
      end

      orders = []
      ActiveRecord::Base.transaction do
        grouped_items.each do |seller_id, items|
          order = current_user.orders_as_buyer.build(
            seller_id: seller_id,
            status: :pending,
            first_name: first_name,
            last_name: last_name,
            delivery_address: address,
            currency: buyer_currency
          )

          items.each do |item|
            product       = Product.find(item["product_id"])
            variant       = item["variant_id"].present? ? Variant.find_by(id: item["variant_id"]) : nil
            requested_qty = item["quantity"].to_i

            if requested_qty > product.stock
              redirect_to cart_path, alert: "Sorry, only #{product.stock} units of #{product.title} are available." and return
            end

            base_price = product.price + (variant&.price_modifier || 0)
            subtotal   = ExchangeRateService.convert(
              base_price * requested_qty,
              from: product.currency,
              to: buyer_currency
            )
            shipping   = (product.shipping_cost || 0) * requested_qty

            order.order_items.build(
              product: product,
              variant: variant,
              quantity: requested_qty,
              subtotal: subtotal,
              shipping: shipping
            )
          end

          order.total = order.order_items.sum { |oi| oi.subtotal + (oi.shipping || 0) }
          order.build_shipment(first_name: first_name, last_name: last_name, address: address, status: :pending)
          order.save!
          decrement_stock!(order)
          notify_seller(order.seller)
          orders << order
        end
      end

      session[:cart] = []
      handle_payment(orders.first, provider, phone_number)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("⚠️ Order Creation Failed: #{e.record.errors.full_messages.join(', ')}")
    respond_to do |format|
      format.html { redirect_to new_order_path(product_id: params[:product_id]), alert: "Failed to create order: #{e.record.errors.full_messages.join(', ')}" }
      format.turbo_stream { redirect_to new_order_path(product_id: params[:product_id]), alert: "Failed to create order." }
    end
  end

  # === GET /orders/:id/receipt ===
  def receipt
    unless @order.payment&.paid?
      redirect_to @order, alert: "Receipt is only available after payment." and return
    end

    pdf = ReceiptGenerator.new(@order, Time.current).generate
    send_data pdf,
              filename: "receipt_order_#{@order.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  # === POST /orders/:id/pay ===
  def pay
    order = Order.find(params[:id])
    service = MpesaStkPushService.new(
      phone_number: params[:phone],
      amount: order.total,
      account_reference: "Order#{order.id}",
      description: "Payment for Order #{order.id}"
    )
    result = service.call
    render json: result
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_order
    @order = Order.find(params[:id])
    unless @order.buyer == current_user || @order.seller == current_user
      redirect_to root_path, alert: "You are not authorized to view this order."
    end
  end

  def notify_seller(seller)
    Notification.create!(user: seller, message: "New order placed", read: false)
  end

  def decrement_stock!(order)
    order.order_items.each do |item|
      product = item.product
      product.update!(stock: product.stock - item.quantity)
    end
  end

  def build_order_for_product(product, variant, quantity, first_name, last_name, address, buyer_currency)
    base_price = product.price + (variant&.price_modifier || 0)
    subtotal   = ExchangeRateService.convert(
      base_price * quantity,
      from: product.currency,
      to: buyer_currency
    )
    shipping   = (product.shipping_cost || 0) * quantity

    order = current_user.orders_as_buyer.build(
      seller: product.seller,
      status: :pending,
      first_name: first_name,
      last_name: last_name,
      delivery_address: address,
      currency: buyer_currency
    )

    order.order_items.build(
      product: product,
      variant: variant,
      quantity: quantity,
      subtotal: subtotal,
      shipping: shipping
    )
    order.total = order.order_items.sum { |oi| oi.subtotal + (oi.shipping || 0) }

    order.build_shipment(
      first_name: first_name,
      last_name: last_name,
      address: address,
      status: :pending
    )
    order
  end

  def order_params
  params.permit(:currency, :provider, :phone_number)
end

def handle_payment(order, provider, phone_number)
  result = PaymentService.process(
    order,
    provider: provider,
    phone_number: phone_number,
    currency: order.currency,
    return_url: order_url(order),
    callback_url: mpesa_callback_url(order_id: order.id, host: ENV["APP_HOST"])
  )

  respond_to do |format|
    if result[:redirect_url]
      format.html         { redirect_to result[:redirect_url], allow_other_host: true }
      format.turbo_stream { redirect_to result[:redirect_url], allow_other_host: true }
    elsif result[:error]
      format.html         { redirect_to order_path(order), alert: result[:error] }
      format.turbo_stream { redirect_to order_path(order), alert: result[:error] }
    else
      format.html         { redirect_to order_path(order), notice: "Order created! Please complete payment." }
      format.turbo_stream { redirect_to order_path(order), notice: "Order created! Please complete payment." }
    end
  end
end

end
