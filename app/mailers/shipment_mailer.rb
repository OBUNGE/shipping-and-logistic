# 📄 app/mailers/shipment_mailer.rb
class ShipmentMailer
  # Send a shipment status update email
  def self.status_update(shipment, new_status)
    order  = shipment.order
    buyer  = order&.buyer
    status = new_status

    # Render HTML body using Rails view rendering, without application layout
    html_content = ApplicationController.render(
      template: "shipment_mailer/status_update",
      assigns: { shipment: shipment, order: order, buyer: buyer, status: status },
      layout: false
    )

    # Auto-generate plain-text fallback by stripping HTML tags
    text_content = strip_tags(html_content).squish

    # Build subject line
    subject = "Shipment Update: Order ##{order.id} is now #{status.humanize}"

    # Fallbacks if buyer is missing
    to_email = buyer&.email || "support@tajaone.app"
    to_name  = buyer&.first_name || "Customer"

    # Send via Brevo
    BrevoEmailService.new.send_email(
      to_email:    to_email,
      to_name:     to_name,
      subject:     subject,
      html_content: html_content,
      text_content: text_content   # ✅ plain-text fallback
    )
  end

  private

  # Use Rails ActionView helper to strip HTML tags
  def self.strip_tags(html)
    ActionView::Base.full_sanitizer.sanitize(html)
  end
end
