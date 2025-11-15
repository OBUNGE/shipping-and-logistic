# 📄 app/mailers/shipment_mailer.rb
class ShipmentMailer
  def self.status_update(shipment, new_status)
    order  = shipment.order
    buyer  = order.buyer
    status = new_status

    # Render the HTML body using Rails view rendering
    html_content = ApplicationController.render(
      template: "shipment_mailer/status_update",
      assigns: { shipment: shipment, order: order, buyer: buyer, status: status }
    )

    subject = "Shipment Update: Order ##{order.id} is now #{status.humanize}"

    BrevoEmailService.new.send_email(
      to_email: buyer.email,
      to_name:  buyer.first_name,
      subject:  subject,
      html_content: html_content
    )
  end
end
