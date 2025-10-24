class OrderMailer < ApplicationMailer
  default from: 'no-reply@yourdomain.com'

  def payment_confirmation(order)
    @order = order
    mail(to: @order.buyer.email, subject: "Payment Confirmation for Order ##{@order.id}")
  end

  def seller_notification(order)
    @order = order
    mail(to: @order.seller.email, subject: "Payment Received for Order ##{@order.id}")
  end
end
