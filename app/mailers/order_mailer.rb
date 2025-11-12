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
        # fallback to guest email stored in payment metadata or order record
        @order.payments.last&.guest_email || @order.email || @order.metadata["customer_email"]
      end

    mail(
      to: recipient_email,
      subject: "Payment Confirmation for Order ##{@order.id}"
    )
  end

  # === Seller Notification ===
  def seller_notification(order)
    @order = order

    # ✅ Handle both registered sellers and guest orders
    recipient_email =
      if @order.seller.present?
        @order.seller.email
      else
        # fallback: notify platform admin/support if no seller is linked
        "admin@yourdomain.com"
      end

    mail(
      to: recipient_email,
      subject: "Payment Received for Order ##{@order.id}"
    )
  end
end
