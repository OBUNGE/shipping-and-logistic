class PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :mpesa_callback, :paystack_callback, :paypal_callback]
  before_action :set_order, except: [:mpesa_callback, :paystack_callback, :paypal_callback]

  # === Create Payment (handles Mpesa, Paystack, PayPal) ===
  def create
    provider        = params[:provider].to_s.downcase
    phone_number    = params[:phone_number].presence || current_user.phone
    buyer_currency  = params[:currency].presence || @order.currency || "USD"

    if provider == "mpesa" && phone_number.blank?
      redirect_to @order, alert: "Phone number is required for M-PESA payments." and return
    end

    @payment = @order.payment || @order.build_payment(
      user: current_user,
      amount: @order.total,
      currency: buyer_currency,
      provider: provider.titleize,
      status: :pending
    )

    if @payment.failed?
      @payment.update(status: :pending)
      flash[:notice] = "Retrying payment for Order ##{@order.id}..."
    end

    result = PaymentService.process(
      @order,
      provider: provider,
      phone_number: phone_number,
      currency: buyer_currency,
      return_url: order_url(@order)
    )

    if result[:checkout_request_id]
      @payment.update!(
        transaction_id: result[:merchant_request_id],
        checkout_request_id: result[:checkout_request_id]
      )
    end

    if result[:redirect_url]
      redirect_to result[:redirect_url]
    elsif result[:error]
      @payment.update(status: :failed)
      redirect_to @order, alert: result[:error]
    else
      redirect_to @order, notice: "STK Push sent to #{phone_number}. Please complete payment on your phone."
    end
  end

  # === Paystack Callback ===
  def paystack_callback
    @order = Order.find(params[:order_id])
    reference = params[:reference]

    unless reference.present?
      redirect_to @order, alert: "❌ Missing Paystack reference" and return
    end

    response = HTTParty.get(
      "https://api.paystack.co/transaction/verify/#{reference}",
      headers: { "Authorization" => "Bearer #{ENV['PAYSTACK_SECRET_KEY']}" }
    )

    body = JSON.parse(response.body) rescue {}
    Rails.logger.info("✅ Paystack verification response: #{body.inspect}")

    if body["status"] && body.dig("data", "status") == "success"
      payment = @order.payment || @order.build_payment(
        provider: "Paystack",
        user: @order.buyer,
        transaction_id: reference,
        amount: body.dig("data", "amount").to_f / 100.0,
        currency: body.dig("data", "currency") || @order.currency,
        status: :paid
      )
      payment.save!
      @order.update!(status: :paid)

      OrderMailer.payment_confirmation(@order).deliver_later
      OrderMailer.seller_notification(@order).deliver_later

      redirect_to @order, notice: "✅ Paystack payment successful"
    else
      error_msg = body["message"] || "Verification failed"
      payment = @order.payment || @order.build_payment(
        provider: "Paystack",
        user: @order.buyer,
        transaction_id: reference,
        status: :failed
      )
      payment.save!
      redirect_to @order, alert: "❌ Paystack payment failed: #{error_msg}"
    end
  end

  # === PayPal Callback ===
  def paypal_callback
    @order = Order.find(params[:order_id])
    order_id = params[:token]

    unless order_id.present?
      redirect_to @order, alert: "❌ Missing PayPal order ID" and return
    end

    env = if Rails.env.production?
            PayPal::LiveEnvironment.new(ENV["PAYPAL_CLIENT_ID"], ENV["PAYPAL_CLIENT_SECRET"])
          else
            PayPal::SandboxEnvironment.new(ENV["PAYPAL_CLIENT_ID"], ENV["PAYPAL_CLIENT_SECRET"])
          end
    client = PayPal::PayPalHttpClient.new(env)

    request = PayPalCheckoutSdk::Orders::OrdersCaptureRequest.new(order_id)
    request.request_body({})

    begin
      response = client.execute(request)
      result   = response.result

      if result.status == "COMPLETED"
        capture = result.purchase_units.first.payments.captures.first
        payment = @order.payment || @order.build_payment(provider: "PayPal")
        payment.update!(
          status: :paid,
          transaction_id: result.id,
          amount: capture.amount.value.to_f,
          currency: capture.amount.currency_code
        )
        @order.update!(status: :paid)

        OrderMailer.payment_confirmation(@order).deliver_later
        OrderMailer.seller_notification(@order).deliver_later

        redirect_to @order, notice: "✅ PayPal payment successful"
      else
        payment = @order.payment || @order.build_payment(provider: "PayPal")
        payment.update!(status: :failed, transaction_id: result.id)
        redirect_to @order, alert: "❌ PayPal payment not completed (#{result.status})"
      end
    rescue => e
      Rails.logger.error("PayPal capture error: #{e.message}")
      redirect_to @order, alert: "❌ PayPal verification failed"
    end
  end

  # === M-PESA Callback ===
  def mpesa_callback
    body = JSON.parse(request.body.read) rescue {}
    Rails.logger.info("✅ M-PESA Callback received: #{body.inspect}")

    result_code = body.dig("Body", "stkCallback", "ResultCode")
    checkout_id = body.dig("Body", "stkCallback", "CheckoutRequestID")

    payment = Payment.find_by(checkout_request_id: checkout_id)

    if payment && result_code == 0
      payment.update!(status: :paid)
      payment.order.update!(status: :paid)

      OrderMailer.payment_confirmation(payment.order).deliver_later
      OrderMailer.seller_notification(payment.order).deliver_later

      Rails.logger.info("✅ M-PESA payment confirmed for Order ##{payment.order.id}")
    elsif payment
      payment.update!(status: :failed)
      Rails.logger.warn("❌ M-PESA payment failed for Order ##{payment.order.id}")
    else
      Rails.logger.error("⚠️ M-PESA callback received for unknown CheckoutRequestID: #{checkout_id}")
    end

    head :ok
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
    if request.format.html? || request.format.turbo_stream?
      unless @order.buyer == current_user
        redirect_to root_path, alert: "Not authorized."
      end
    end
  end
end
