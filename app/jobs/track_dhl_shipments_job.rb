class TrackDhlShipmentsJob < ApplicationJob
  queue_as :default

  def perform
    Shipment.where(carrier: "DHL", status: ["pending", "in_transit"]).find_each do |shipment|
      result = ShipmentTrackingService.new(shipment).track
      if result[:status].present?
        shipment.update(status: result[:status])
        ShipmentStatusLog.create!(
          shipment: shipment,
          status: result[:status],
          changed_by: nil,
          changed_at: Time.current
        )
      end
    end
  end
end
