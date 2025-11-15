require "httparty"
require "base64"

class MpesaGateway
  DARAJA_BASE_URL = "https://sandbox.safaricom.co.ke"
  OAUTH_URL       = "#{DARAJA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials"
  STK_PUSH_URL    = "#{DARAJA_BASE_URL}/mpesa/stkpush/v1/processrequest"

  MAX_RETRIES     = 3
  RETRY_DELAY     = 5.seconds

  def initialize(order:, phone_number:, amount:, account_reference:, description:, callback_url:)
    @order             = order
    @phone_number      = phone_number
    @amount            = amount_kes(amount)
    @account_reference = account_reference
    @description       = description
    @callback_url      = callback_url
  end

  def initiate
    attempts = 0

    begin
      attempts += 1
      token = fetch_token
      return { error: "Failed to fetch M-PESA token" } unless token

      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      password  = Base64.strict_encode64("#{shortcode}#{passkey}#{timestamp}")

      payload = {
        BusinessShortCode: shortcode,
        Password:          password,
        Timestamp:         timestamp,
        TransactionType:   "CustomerPayBillOnline",
        Amount:            @amount.to_i,
        PartyA:            @phone_number,
        PartyB:            shortcode,
        PhoneNumber:       @phone_number,
        CallBackURL:       @callback_url,
        AccountReference:  @account_reference,
        TransactionDesc:   @description
      }

      Rails.logger.info("📡 Sending STK Push (attempt #{attempts}) with callback: #{@callback_url}")
      Rails.logger.info("📦 STK Push Payload: #{payload.inspect}")

      response = HTTParty.post(
        STK_PUSH_URL,
        headers: {
          "Authorization" => "Bearer #{token}",
          "Content-Type"  => "application/json"
        },
        body: payload.to_json
      )

      parsed = JSON.parse(response.body) rescue {}
      Rails.logger.info("📬 STK Push Response: #{parsed.inspect}")

      # Return parsed response + HTTP status
      parsed.merge("http_status" => response.code)

    rescue => e
      Rails.logger.error("❌ M-PESA initiation exception (attempt #{attempts}): #{e.message}")

      if attempts < MAX_RETRIES
        Rails.logger.info("⏳ Retrying STK Push in #{RETRY_DELAY}...")
        sleep RETRY_DELAY
        retry
      else
        Rails.logger.error("❌ All retries failed for Order ##{@order.id}")
        { error: "M-PESA initiation failed after #{MAX_RETRIES} attempts" }
      end
    end
  end

  private

  # ✅ Always return KES since your app now stores currency in KES
  def amount_kes(override_amount)
    override_amount.presence || @order.total
  end

  def fetch_token
    auth = Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")
    response = HTTParty.get(
      OAUTH_URL,
      headers: { "Authorization" => "Basic #{auth}" }
    )
    JSON.parse(response.body)["access_token"] rescue nil
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
end
