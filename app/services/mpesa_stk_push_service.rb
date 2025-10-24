require "base64"
require "httparty"

class MpesaStkPushService
  OAUTH_URL   = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
  STK_PUSH_URL = "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"

  def initialize(order:, phone_number:, amount:, account_reference:, description:)
    @order             = order
    @phone_number      = normalize_phone(phone_number)
    @amount            = amount
    @account_reference = account_reference
    @description       = description
  end

  def call
    token = fetch_token
    return { error: "Failed to fetch token" } unless token

    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    password  = Base64.strict_encode64("#{shortcode}#{passkey}#{timestamp}")

    body = {
      BusinessShortCode: shortcode,
      Password:          password,
      Timestamp:         timestamp,
      TransactionType:   "CustomerPayBillOnline",
      Amount:            @amount,
      PartyA:            @phone_number, # customer phone
      PartyB:            shortcode,     # paybill/till
      PhoneNumber:       @phone_number,
      CallBackURL:       callback_url,
      AccountReference:  @account_reference,
      TransactionDesc:   @description
    }

    response = HTTParty.post(
      STK_PUSH_URL,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type"  => "application/json"
      },
      body: body.to_json
    )

    JSON.parse(response.body) rescue { error: "Invalid JSON response" }
  rescue => e
    Rails.logger.error("M-PESA STK Push error: #{e.message}")
    { error: e.message }
  end

  private

  def fetch_token
    response = HTTParty.get(
      OAUTH_URL,
      basic_auth: {
        username: consumer_key,
        password: consumer_secret
      }
    )
    return nil unless response.code == 200
    JSON.parse(response.body)["access_token"]
  rescue => e
    Rails.logger.error("M-PESA token fetch error: #{e.message}")
    nil
  end

  def consumer_key
    ENV["MPESA_CONSUMER_KEY"]
  end

  def consumer_secret
    ENV["MPESA_CONSUMER_SECRET"]
  end

  def shortcode
    ENV["MPESA_SHORTCODE"]
  end

  def passkey
    ENV["MPESA_PASSKEY"]
  end

  def callback_url
    Rails.application.routes.url_helpers.mpesa_callback_url(
      host: ENV.fetch("APP_HOST", "http://localhost:3000"),
      order_id: @order.id
    )
  end

  def normalize_phone(phone)
    phone = phone.to_s.strip
    return phone if phone.start_with?("254")
    phone.sub(/^0/, "254")
  end
end
