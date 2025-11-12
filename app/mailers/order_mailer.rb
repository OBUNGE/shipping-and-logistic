# app/mailers/order_mailer.rb
class OrderMailer < ApplicationMailer
  default from: 'no-reply@yourdomain.com'

  # === Buyer / Guest Payment Confirmation ===
  def payment_confirmation(order_id)
    @order = Order.find(order_id)

    # ✅ Handle both logged-in buyers and guests
    recipient_email =
      if @order.buyer.present?
        @order.buyer.email
      else
        # fallback to guest email stored in the order record
        @order.email
      end

    mail(
      to: recipient_email,
      subject: "Payment Confirmation for Order ##{@order.id}"
    )
  end

  # === Seller Notification ===
  def seller_notification(order_id)
    @order = Order.find(order_id)

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
