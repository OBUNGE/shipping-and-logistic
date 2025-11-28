# app/services/payment_service.rb
class PaymentService
  def self.process(order, provider:, phone_number: nil, email: nil, return_url: nil, callback_url: nil, currency: nil)
    provider = provider.to_s.downcase
    # Default currency should be KES, not USD
    currency ||= order.currency || "KES"

    case provider
    when "mpesa"
      # M-PESA only supports KES
      amount_in_kes = if currency == "USD"
                         ExchangeRateService.convert(order.total, from: "USD", to: "KES")
                       else
                         order.total
                       end

      callback_url ||= Rails.application.routes.url_helpers.mpesa_callback_url(
        order_id: order.id,
        host: ENV.fetch("APP_HOST", "tajaone.app")
      )

      MpesaStkPushService.new(
        order: order,
        phone_number: phone_number, # raw input, service will normalize
        amount: amount_in_kes,
        account_reference: "Order_#{order.id}",
        description: "Payment for Order #{order.id}",
        callback_url: callback_url
      ).call

    when "paypal"
      # PayPal typically requires USD, so convert if needed
      amount_in_usd = if currency == "KES"
                         ExchangeRateService.convert(order.total, from: "KES", to: "USD")
                       else
                         order.total
                       end

      PaypalGateway.new(
        order: order,
        return_url: return_url || Rails.application.routes.url_helpers.order_url(order, host: ENV.fetch("APP_HOST", "tajaone.app")),
        currency: "USD", # force USD for PayPal
        amount: amount_in_usd
      ).initiate

    when "paystack"
      # Paystack can handle both USD and KES, so just pass through
      PaystackPaymentService.new(
        order,
        currency, # either "KES" or "USD"
        email: email || order.email || order.buyer&.email
      ).create_payment

    when "pod"
      # ✅ Pay on Delivery (Cash on Delivery)
      order.payments.create!(
        provider: "POD",
        amount: order.total,
        currency: currency,
        status: :pending
      )
      { message: "Order placed with Pay on Delivery. Please prepare for cash collection." }

    else
      raise ArgumentError, "Unsupported payment provider: #{provider}"
    end
  end
end
