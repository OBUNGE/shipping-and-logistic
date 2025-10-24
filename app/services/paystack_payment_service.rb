class PaystackPaymentService
  def initialize(order, payment_currency)
    @order = order
    @payment_currency = payment_currency
  end

  def create_payment
    amount_in_currency = CurrencyConverter.convert(
      @order.total,
      from: @order.currency,
      to: @payment_currency
    )

    Payment.create!(
      order: @order,
      user: @order.buyer,
      amount: amount_in_currency,
      currency: @payment_currency,
      provider: "Paystack",
      status: "pending"
    )
  end
end
