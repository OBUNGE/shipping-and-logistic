# app/services/paypal_gateway.rb
require "paypal-checkout-sdk"

class PaypalGateway
  include Rails.application.routes.url_helpers

  def initialize(order, return_url, currency: nil)
    @order      = order
    @return_url = return_url
    @currency   = currency || order.currency || "USD"
  end

  def default_url_options
    { host: "localhost", port: 3000 } # ✅ required for route helpers to work
  end

  def client
    env = if Rails.env.production?
            PayPal::LiveEnvironment.new(ENV["PAYPAL_CLIENT_ID"], ENV["PAYPAL_CLIENT_SECRET"])
          else
            PayPal::SandboxEnvironment.new(ENV["PAYPAL_CLIENT_ID"], ENV["PAYPAL_CLIENT_SECRET"])
          end
    PayPal::PayPalHttpClient.new(env)
  end

  def initiate
    request = PayPalCheckoutSdk::Orders::OrdersCreateRequest.new
    request.prefer("return=representation")
    request.request_body({
      intent: "CAPTURE",
      purchase_units: [{
        amount: {
          currency_code: @currency,
          value: sprintf("%.2f", @order.total)
        }
      }],
      application_context: {
        return_url: callback_url(success: true),
        cancel_url: callback_url(cancel: true),
        brand_name: "TradePort",
        user_action: "PAY_NOW"
      }
    })

    response = client.execute(request)
    approve_link = response.result.links.find { |l| l.rel == "approve" }&.href

    if approve_link
      @order.create_payment!(
        user:           @order.buyer,
        provider:       "PayPal",
        amount:         @order.total,
        currency:       @currency,
        status:         :pending,
        transaction_id: response.result.id
      )
      { redirect_url: approve_link }
    else
      { error: "PayPal did not return approval link" }
    end
  rescue => e
    Rails.logger.error("PaypalGateway error: #{e.message}")
    { error: "PayPal initiation failed" }
  end

  private

  def callback_url(params = {})
  paypal_callback_order_payment_url(@order, params)
end

end
