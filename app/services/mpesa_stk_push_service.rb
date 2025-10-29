require "base64"
require "httparty"

class MpesaStkPushService
  def initialize(order:, phone_number:, amount:, account_reference:, description:, callback_url: nil)
    @order             = order
    @phone_number      = normalize_phone(phone_number)
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
    gateway.initiate
  end

  private

  def normalize_phone(phone)
    phone = phone.to_s.strip
    return phone if phone.start_with?("254")
    phone.sub(/^0/, "254")
  end

  def default_callback_url
    Rails.application.routes.url_helpers.mpesa_callback_url(
      host: ENV.fetch("APP_HOST", "http://localhost:3000"),
      order_id: @order.id
    )
  end
end
