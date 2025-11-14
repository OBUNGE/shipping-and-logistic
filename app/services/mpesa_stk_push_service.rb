require "base64"
require "httparty"

class MpesaStkPushService
  def initialize(order:, phone_number:, amount:, account_reference:, description:, callback_url: nil)
    @order             = order
    @phone_number       = normalize_phone(phone_number)
    @amount            = amount
    @account_reference = account_reference
    @description       = description
    @callback_url      = callback_url || default_callback_url
  end

  def call
    gateway = MpesaGateway.new(
      order: @order,
      phone_number: @phone_number,
      amount: @amount,
      account_reference: @account_reference,
      description: @description,
      callback_url: @callback_url
    )

    response = gateway.initiate

    if response && response["ResponseCode"] == "0"
      Payment.create!(
        order:               @order,
        amount:              @amount,
        status:              "pending",
        provider:            "mpesa",
        checkout_request_id: response["CheckoutRequestID"],
        merchant_request_id: response["MerchantRequestID"],
        message:             response["ResponseDescription"]
      )
    else
      Rails.logger.error("❌ STK Push failed: #{response.inspect}")
    end

    response
  rescue => e
    Rails.logger.error("❌ MpesaStkPushService error: #{e.message}")
    { error: "M-PESA STK Push failed" }
  end

  private

  def normalize_phone(phone)
    phone = phone.to_s.strip.gsub(/\D/, "")
    phone = phone.sub(/^0/, "254")
    phone = phone.sub(/^\+254/, "254")
    phone.start_with?("254") ? phone : "254#{phone}"
  end

  def default_callback_url
    Rails.application.routes.url_helpers.mpesa_callback_url(
      host: ENV.fetch("APP_HOST", "http://localhost:3000"),
      order_id: @order.id
    )
  end
end
