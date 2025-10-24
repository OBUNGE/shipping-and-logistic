class ShipmentMailer < ApplicationMailer
  default from: "no-reply@yourdomain.com"

  def status_update(shipment, new_status)
    @shipment = shipment
    @order    = shipment.order
    @buyer    = @order.buyer
    @status   = new_status

    mail(
      to: @buyer.email,
      subject: "Shipment Update: Order ##{@order.id} is now #{@status.humanize}"
    )
  end
end
