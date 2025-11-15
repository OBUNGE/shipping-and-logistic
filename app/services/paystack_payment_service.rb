# app/services/paystack_payment_service.rb
class PaystackPaymentService
  def initialize(order, payment_currency = "KES", email:)
    @order = order
    @payment_currency = payment_currency
    @customer_email = email
    @gateway = PaystackGateway.new(
      order: order,
      return_url: Rails.application.routes.url_helpers.order_url(
        order,
        host: ENV.fetch("APP_HOST", "tajaone.app")
      ),
      currency: payment_currency,
      email: @customer_email
    )
  end

  def create_payment
    # Step 1: Convert amount into target currency
    amount_in_currency = ExchangeRateService.convert(
      @order.total,
      from: @order.currency,
      to: @payment_currency
    )

    # Step 2: Initialize transaction with Paystack
    response = @gateway.initiate
    body = response.is_a?(Hash) ? response : JSON.parse(response.body) rescue {}

    if body[:redirect_url] || body.dig("data", "authorization_url")
      reference    = body[:transaction_id] || body.dig("data", "reference")
      redirect_url = body[:redirect_url]   || body.dig("data", "authorization_url")

      # Step 3: Create Payment record in DB
      Payment.create!(
        order:         @order,
        user:          @order.buyer,
        guest_email:   @customer_email,       # ✅ capture guest email
        guest_phone:   @order.phone_number,   # ✅ capture guest phone
        amount:        amount_in_currency,
        currency:      @payment_currency,
        provider:      "paystack",
        status:        :pending,
        transaction_id: reference
      )

      # Step 4: Return redirect URL for controller
      { redirect_url: redirect_url }
    else
      Rails.logger.error("PaystackPaymentService error: #{body.inspect}")
      { error: body["message"] || "Unable to initialize Paystack payment" }
    end
  rescue => e
    Rails.logger.error("PaystackPaymentService exception: #{e.message}")
    { error: "Paystack initiation failed" }
  end
end
