# app/jobs/shipment_email_job.rb
class ShipmentEmailJob < ApplicationJob
  queue_as :default

  def perform(shipment_id, new_status)
    shipment = Shipment.find(shipment_id)
    order    = shipment.order
    buyer    = order&.buyer

    # Render HTML body using Rails view rendering, without layout
    html_content = ApplicationController.render(
      template: "shipment_mailer/status_update",
      assigns: { shipment: shipment, order: order, buyer: buyer, status: new_status },
      layout: false
    )

    # Auto-generate plain-text fallback
    text_content = ActionView::Base.full_sanitizer.sanitize(html_content).squish

    # Determine recipient email and name
    to_email =
      if buyer&.email.present?
        buyer.email
      elsif order.email.present?
        order.email
      else
        "sales@tajaone.app" # final fallback
      end

    to_name = buyer&.first_name || order.first_name || "Customer"

    # Send via Brevo API service
    BrevoEmailService.new.send_email(
      to_email:    to_email,
      to_name:     to_name,
      subject:     "Shipment Update: Order ##{order.id} is now #{new_status.humanize}",
      html_content: html_content,
      text_content: text_content
    )
  end
end
