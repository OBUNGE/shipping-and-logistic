# app/mailers/order_mailer.rb
class OrderMailer < ApplicationMailer
  layout false

  def payment_confirmation(order_id)
    order = Order.find(order_id)
    recipient_email = order.buyer&.email || order.email

    begin
      html_content = ApplicationController.renderer.render(
        partial: "order_mailer/payment_confirmation",
        locals: { order: order }
      )

      BrevoEmailService.new.send_email(
        to_email: recipient_email,
        to_name: [order.first_name, order.last_name].compact.join(" "),
        subject: "Payment Confirmation for Order ##{order.id}",
        html_content: html_content
      )
    rescue => e
      Rails.logger.error("❌ Brevo send failed (payment_confirmation): #{e.message}")
    end
  end

  def seller_notification(order_id)
    order = Order.find(order_id)
    recipient_email = order.seller&.email || "admin@yourdomain.com"
    recipient_name  = order.seller&.name || "Seller"

    begin
      html_content = ApplicationController.renderer.render(
        partial: "order_mailer/seller_notification",
        locals: { order: order }
      )

      BrevoEmailService.new.send_email(
        to_email: recipient_email,
        to_name: recipient_name,
        subject: "Payment Received for Order ##{order.id}",
        html_content: html_content
      )
    rescue => e
      Rails.logger.error("❌ Brevo send failed (seller_notification): #{e.message}")
    end
  end
end
