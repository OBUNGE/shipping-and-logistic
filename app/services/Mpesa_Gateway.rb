require "httparty"
require "base64"

class MpesaGateway
  BASE_URLS = {
    sandbox:    "https://sandbox.safaricom.co.ke",
    production: "https://api.safaricom.co.ke"
  }.freeze

  MAX_RETRIES  = 3
  RETRY_DELAY  = 5.seconds

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
        TransactionType: "CustomerPayBillOnline",
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
        stk_push_url,
        headers: {
          "Authorization" => "Bearer #{token}",
          "Content-Type"  => "application/json"
        },
        body: payload.to_json
      )

      parsed = JSON.parse(response.body) rescue {}
      Rails.logger.info("📬 STK Push Response: #{parsed.inspect}")

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

  def amount_kes(override_amount)
    override_amount.presence || @order.total
  end

  def fetch_token
    auth = Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")
    response = HTTParty.get(
      oauth_url,
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

  def environment
    ENV.fetch("MPESA_ENV", "sandbox").to_sym
  end

  def base_url
    BASE_URLS[environment]
  end

  def oauth_url
    "#{base_url}/oauth/v1/generate?grant_type=client_credentials"
  end

  def stk_push_url
    "#{base_url}/mpesa/stkpush/v1/processrequest"
  end
end
