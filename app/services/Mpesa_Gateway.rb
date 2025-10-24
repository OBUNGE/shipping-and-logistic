# app/services/mpesa_gateway.rb
require "httparty"
require "base64"

class MpesaGateway
  DARAJA_BASE_URL = "https://sandbox.safaricom.co.ke"
  SHORTCODE = ENV["MPESA_SHORTCODE"] || "174379"
  PASSKEY   = ENV["MPESA_PASSKEY"]

  def initialize(order, phone_number, amount = nil)
    @order        = order
    @phone_number = phone_number
    # Always convert to KES because M-PESA only supports KES
    @amount_kes   = if order.currency == "USD"
                      ExchangeRateService.convert(order.total, from: "USD", to: "KES")
                    else
                      order.total
                    end
    # Allow override if amount passed explicitly
    @amount_kes = amount if amount.present?
  end

  def initiate
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    password  = Base64.strict_encode64("#{SHORTCODE}#{PASSKEY}#{timestamp}")

    response = HTTParty.post(
      "#{DARAJA_BASE_URL}/mpesa/stkpush/v1/processrequest",
      headers: {
        "Authorization" => "Bearer #{generate_token}",
        "Content-Type"  => "application/json"
      },
      body: {
        BusinessShortCode: SHORTCODE,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: @amount_kes.to_i, # must be integer
        PartyA: @phone_number,
        PartyB: SHORTCODE,
        PhoneNumber: @phone_number,
        CallBackURL: Rails.application.routes.url_helpers.mpesa_callback_url,
        AccountReference: "Order_#{@order.id}",
        TransactionDesc: "Payment for Order #{@order.id}"
      }.to_json
    )

    if response.code == 200 && response["ResponseCode"] == "0"
      checkout_id = response["CheckoutRequestID"]
      @order.create_payment!(
        user:           @order.buyer,
        provider:       "M-PESA",
        amount:         @amount_kes,
        currency:       "KES", # always KES for M-PESA
        status:         :pending,
        transaction_id: checkout_id
      )
      { redirect_url: Rails.application.routes.url_helpers.order_path(@order) }
    else
      error_msg = response["errorMessage"] || response["errorDescription"] || "M-PESA STK push failed"
      { error: error_msg }
    end
  rescue => e
    Rails.logger.error("M-PESA initiation error: #{e.message}")
    { error: "M-PESA initiation failed" }
  end

  private

  def generate_token
    consumer_key    = ENV["MPESA_CONSUMER_KEY"]
    consumer_secret = ENV["MPESA_CONSUMER_SECRET"]
    auth = Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")

    response = HTTParty.get(
      "#{DARAJA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials",
      headers: { "Authorization" => "Basic #{auth}" }
    )
    response["access_token"]
  end

  def extract_metadata(items, key)
    item = items.find { |i| i["Name"] == key }
    item ? item["Value"] : nil
  end
end
