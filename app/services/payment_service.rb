class PaymentService
  def self.process(order, provider:, phone_number: nil, email: nil, return_url: nil, callback_url: nil, currency: nil)
    provider = provider.to_s.downcase
    currency ||= order.currency || "USD"

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
    host: ENV.fetch("APP_HOST", "http://localhost:3000")
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
      PaypalGateway.new(
        order: order,
        return_url: return_url,
        currency: currency
      ).initiate

    when "paystack"
      amount_in_minor_units = (order.total * 100).to_i
      PaystackPaymentService.new(
        order: order,
        return_url: return_url,
        amount: amount_in_minor_units,
        currency: currency,
        email: email || order.email || order.buyer&.email
      ).initiate

    else
      raise ArgumentError, "Unsupported payment provider: #{provider}"
    end
  end
end
