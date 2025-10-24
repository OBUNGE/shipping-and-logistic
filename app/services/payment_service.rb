class PaymentService
  def self.process(order, provider:, phone_number: nil, return_url: nil, currency: nil)
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

      MpesaGateway.new(order, phone_number, amount_in_kes).initiate

    when "paypal"
      # PayPal supports both USD and KES
      PaypalGateway.new(order, return_url, currency: currency).initiate

    when "paystack"
      # Paystack supports USD and KES, amount must be in smallest unit (cents/kobo)
      amount_in_minor_units = (order.total * 100).to_i
      PaystackGateway.new(order, return_url, amount: amount_in_minor_units, currency: currency).initiate

    else
      raise ArgumentError, "Unsupported payment provider: #{provider}"
    end
  end
end
