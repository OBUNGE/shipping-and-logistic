class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def dhl
    data = JSON.parse(request.body.read) rescue {}
    tracking_number = data["trackingNumber"]
    status = data.dig("status", "statusCode")

    shipment = Shipment.find_by(tracking_number: tracking_number)
    if shipment && status.present?
      shipment.update(status: status)
      ShipmentStatusLog.create!(
        shipment: shipment,
        status: status,
        changed_by: nil,
        changed_at: Time.current
      )
      head :ok
    else
      Rails.logger.warn("⚠️ DHL webhook: shipment not found or status missing")
      head :not_found
    end
  end
end
