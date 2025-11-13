require "base64"
require "httparty"

MpesaStkPushService.new(
  order: @order,
  phone_number: params[:mpesa_phone].presence || @order.phone_number,
  amount: @order.total,
  account_reference: "Order_#{@order.id}",
  description: "Payment for Order #{@order.id}"
).call

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

    # ✅ Create a Payment record immediately after STK Push initiation
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

  # ✅ Normalize phone to Safaricom’s required format (2547XXXXXXXX)
  def normalize_phone(phone)
    phone = phone.to_s.strip.gsub(/\D/, "") # remove non-digits
    phone = phone.sub(/^0/, "254")          # replace leading 0 with 254
    phone = phone.sub(/^\+254/, "254")      # remove leading +
    phone.start_with?("254") ? phone : "254#{phone}"
  end

  def default_callback_url
    Rails.application.routes.url_helpers.mpesa_callback_url(
      host: ENV.fetch("APP_HOST", "http://localhost:3000"),
      order_id: @order.id
    )
  end
end
