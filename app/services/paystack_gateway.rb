require "httparty"

class PaystackGateway
  include HTTParty
  base_uri "https://api.paystack.co"

  def initialize(order, return_url, amount: nil, currency: nil)
    @order      = order
    @return_url = return_url
    @amount     = amount || (order.total * 100).to_i # default: order total in minor units
    @currency   = currency || order.currency || "USD"
  end

  def initiate
    response = self.class.post(
      "/transaction/initialize",
      headers: {
        "Authorization" => "Bearer #{ENV['PAYSTACK_SECRET_KEY']}",
        "Content-Type"  => "application/json"
      },
      body: {
        email:        @order.buyer.email,
        amount:       @amount,          # already in minor units
        currency:     @currency,
        callback_url: callback_url
      }.to_json
    )

    body = JSON.parse(response.body) rescue {}
    if body["status"] && body.dig("data", "authorization_url")
      @order.create_payment!(
        user:           @order.buyer,
        provider:       "Paystack",
        amount:         @amount.to_f / 100.0, # store in major units
        currency:       @currency,
        status:         :pending,
        transaction_id: body.dig("data", "reference")
      )
      { redirect_url: body.dig("data", "authorization_url") }
    else
      { error: body["message"] || "Paystack initiation failed" }
    end
  rescue => e
    Rails.logger.error("PaystackGateway error: #{e.message}")
    { error: "Paystack initiation failed" }
  end

  private

  def callback_url
    # Ensure you have this route defined in config/routes.rb
    Rails.application.routes.url_helpers.payments_paystack_callback_url(@order)
  end
end
