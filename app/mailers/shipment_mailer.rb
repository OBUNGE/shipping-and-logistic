# 📄 app/mailers/shipment_mailer.rb
class ShipmentMailer
  def self.status_update(shipment, new_status)
    order  = shipment.order
    buyer  = order.buyer
    status = new_status

    # Render HTML body using Rails view rendering, without application layout
    html_content = ApplicationController.render(
      template: "shipment_mailer/status_update",
      assigns: { shipment: shipment, order: order, buyer: buyer, status: status },
      layout: false
    )

    # Generate plain-text fallback (strip tags or build manually)
    text_content = <<~TEXT
      Hi #{buyer.first_name},

      Your shipment for Order ##{order.id} has been updated to #{status.humanize}.

      Carrier: #{shipment.carrier}
      Tracking Number: #{shipment.tracking_number}
      Estimated Delivery: #{shipment.estimated_delivery || "N/A"}

      Thank you for shopping with us!
      Best regards,
      Tajaone team
    TEXT

    subject = "Shipment Update: Order ##{order.id} is now #{status.humanize}"

    BrevoEmailService.new.send_email(
      to_email: buyer.email,
      to_name:  buyer.first_name,
      subject:  subject,
      html_content: html_content,
      text_content: text_content   # ✅ plain-text fallback
    )
  end
end
