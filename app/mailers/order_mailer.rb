class OrderMailer < ApplicationMailer
  default from: 'no-reply@yourdomain.com'

  # === Buyer / Guest Payment Confirmation ===
  def payment_confirmation(order)
    @order = order

    # ✅ Handle both logged-in buyers and guests
    recipient_email =
      if @order.buyer.present?
        @order.buyer.email
      else
        # fallback to guest email stored in payment or order
        @order.payments.last&.guest_email || @order.email
      end

    mail(to: recipient_email, subject: "Payment Confirmation for Order ##{@order.id}")
  end

  # === Seller Notification ===
  def seller_notification(order)
    @order = order

    # Seller is always a registered user
    mail(to: @order.seller.email, subject: "Payment Received for Order ##{@order.id}")
  end
end
