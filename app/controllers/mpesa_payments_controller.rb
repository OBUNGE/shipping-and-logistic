# app/controllers/mpesa_payments_controller.rb
class MpesaPaymentsController < ApplicationController
  # Safaricom sends callbacks from external servers — skip CSRF protection
  skip_before_action :verify_authenticity_token

  def stk_push
    service = MpesaStkPushService.new(
      phone_number: params[:phone_number],
      amount: params[:amount],
      account_reference: "Order_#{params[:order_id]}",
      description: "Payment for Order #{params[:order_id]}"
    )
    result = service.call
    render json: result
  end

  # POST /mpesa_payments/callback
  def callback
    Rails.logger.info("📩 M-PESA Callback Received: #{params.to_unsafe_h.inspect}")

    stk_callback        = params.dig("Body", "stkCallback") || {}
    result_code         = stk_callback["ResultCode"].to_i
    result_desc         = stk_callback["ResultDesc"]
    checkout_request_id = stk_callback["CheckoutRequestID"]
    callback_metadata   = stk_callback.dig("CallbackMetadata", "Item") || []

    # Extract important data
    amount        = extract_metadata(callback_metadata, "Amount")
    mpesa_receipt = extract_metadata(callback_metadata, "MpesaReceiptNumber")
    phone_number  = extract_metadata(callback_metadata, "PhoneNumber")
    account_ref   = extract_metadata(callback_metadata, "AccountReference")

    unless account_ref.present?
      Rails.logger.error("⚠️ M-PESA Callback: Missing AccountReference")
      return head :bad_request
    end

    order_id = account_ref.to_s.gsub("Order_", "")
    order = Order.find_by(id: order_id)
    unless order
      Rails.logger.error("⚠️ M-PESA Callback: Order not found for ID #{order_id}")
      return head :not_found
    end

    payment = Payment.find_or_initialize_by(order: order) do |p|
      p.user                = order.buyer
      p.provider            = "M-PESA"
      p.checkout_request_id = checkout_request_id
      p.amount              = amount
      p.status              = :pending
    end

    if result_code.zero?
      # ✅ Payment Successful
      ActiveRecord::Base.transaction do
        payment.update!(
          mpesa_receipt_number: mpesa_receipt,
          amount: amount,
          status: :paid,
          transaction_id: checkout_request_id
        )
        order.update!(status: :paid)
      end

      Rails.logger.info("✅ Order ##{order.id} marked as PAID — M-PESA Receipt: #{mpesa_receipt}")
      send_notifications(order)
    else
      # ❌ Payment Failed
      payment.update!(
        mpesa_receipt_number: mpesa_receipt,
        amount: amount || 0,
        status: :failed,
        transaction_id: checkout_request_id
      )
      Rails.logger.warn("❌ Payment for Order ##{order.id} failed: #{result_desc}")
    end

    render json: { ResultCode: 0, ResultDesc: "Callback received successfully" }
  end

  private

  def extract_metadata(items, key)
    items.find { |i| i["Name"] == key }&.dig("Value")
  end

  def send_notifications(order)
    OrderMailer.payment_confirmation(order).deliver_later
    OrderMailer.seller_notification(order).deliver_later
  rescue => e
    Rails.logger.error("⚠️ Notification Error: #{e.message}")
  end
end
