require "httparty"

class PaystackGateway
  include HTTParty
  include Rails.application.routes.url_helpers

  base_uri "https://api.paystack.co"

  def initialize(order:, return_url:, amount: nil, currency: nil)
    @order      = order
    @return_url = return_url
    @amount     = amount || (order.total * 100).to_i # Paystack expects minor units
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
        amount:       @amount,
        currency:     @currency,
        callback_url: callback_url
      }.to_json
    )

    body = JSON.parse(response.body) rescue {}
    if body["status"] && body.dig("data", "authorization_url")
      @order.payments.create!(
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
    paystack_callback_order_payments_url(@order)
  end

def default_url_options
  uri = URI.parse(ENV["APP_HOST"] || "http://localhost:3000")
  options = {
    host: uri.host,
    protocol: uri.scheme
  }
  options[:port] = uri.port unless [80, 443].include?(uri.port)
  options
end
end
