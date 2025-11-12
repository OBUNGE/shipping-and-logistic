# app/mailers/order_mailer.rb
class OrderMailer < ApplicationMailer
  # We’re bypassing ActionMailer’s SMTP delivery and using Brevo API directly

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

    BrevoEmailService.new.send_email(
      to_email: recipient_email,
      to_name: [@order.first_name, @order.last_name].compact.join(" "),
      subject: "Payment Confirmation for Order ##{@order.id}",
      html_content: ApplicationController.render(
        template: "order_mailer/payment_confirmation",
        assigns: { order: @order }
      )
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

    BrevoEmailService.new.send_email(
      to_email: recipient_email,
      to_name: @order.seller&.name || "Admin",
      subject: "Payment Received for Order ##{@order.id}",
      html_content: ApplicationController.render(
        template: "order_mailer/seller_notification",
        assigns: { order: @order }
      )
    )
  end
end
