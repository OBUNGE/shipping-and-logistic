# app/services/paystack_payment_service.rb
class PaystackPaymentService
  def initialize(order, payment_currency = "KES", email:)
    @order = order
    @payment_currency = payment_currency # can be "KES" or "USD"
    @customer_email = email

    @gateway = PaystackGateway.new(
      order: order,
      return_url: Rails.application.routes.url_helpers.order_url(
        order,
        host: ENV.fetch("APP_HOST", "tajaone.app")
      ),
      currency: @payment_currency,
      email: @customer_email
    )
  end

  def create_payment
    # Step 1: Normalize amount into target currency
    amount_in_currency =
      if @order.currency == @payment_currency
        @order.total
      else
        ExchangeRateService.convert(
          @order.total,
          from: @order.currency,
          to: @payment_currency
        )
      end

    # Step 2: Initialize transaction with Paystack
    response = @gateway.initiate
    body = response.is_a?(Hash) ? response : JSON.parse(response.body) rescue {}

    if body[:redirect_url] || body.dig("data", "authorization_url")
      reference    = body[:transaction_id] || body.dig("data", "reference")
      redirect_url = body[:redirect_url]   || body.dig("data", "authorization_url")

      # Step 3: Persist Payment record
      Payment.create!(
        order:          @order,
        user:           @order.buyer,
        guest_email:    @customer_email,
        guest_phone:    @order.phone_number,
        amount:         amount_in_currency,
        currency:       @payment_currency,   # ✅ stored as KES or USD
        provider:       "paystack",
        status:         :pending,
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
