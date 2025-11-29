require 'net/http'
require 'json'

class ShipmentTrackingService
  # Example carriers (can expand)
  CARRIERS = {
    "sendy" => "https://api.sendyit.com/v1/track",
    "dhl" => "https://api.dhl.com/track/shipments",
    "posta" => "https://posta.co.ke/api/track"
  }

  def initialize(shipment)
    @shipment = shipment
  end

  def track
    case @shipment.carrier.downcase
    when "sendy"
      track_sendy
    when "dhl"
      track_dhl
    when "posta"
      track_posta
    else
      { status: "unknown", message: "Carrier not supported yet" }
    end
  end

  private

  # 🔹 Sendy API simulation
  def track_sendy
    # Here you’d use your Sendy API key for live data.
    # Example placeholder for demonstration:
    response = {
      tracking_number: @shipment.tracking_number,
      status: ["Pending", "In Transit", "Delivered"].sample,
      message: "Package is being processed by Sendy"
    }

    update_shipment(response)
  end

  # 🔹 DHL API (requires API key)
  def track_dhl
    uri = URI("#{CARRIERS["dhl"]}?trackingNumber=#{@shipment.tracking_number}")
    request = Net::HTTP::Get.new(uri)
    request["DHL-API-Key"] = ENV["DHL_API_KEY"] || "demo-key"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    data = JSON.parse(response.body)
    status = data.dig("shipments", 0, "status", "statusCode") rescue "unknown"

    update_shipment({ tracking_number: @shipment.tracking_number, status: status })
  end

  # 🔹 Posta Kenya API (mock)
  def track_posta
    response = {
      tracking_number: @shipment.tracking_number,
      status: ["Dispatched", "In Transit", "Delivered"].sample,
      message: "Posta Kenya update"
    }

    update_shipment(response)
  end

  # 🔹 Update shipment record in DB
 def update
  @shipment = Shipment.find(params[:id])
  if @shipment.update(shipment_params.merge(order_id: params[:order_id]))
    redirect_to @shipment, notice: "Shipment updated successfully"
  else
    render :edit, status: :unprocessable_entity
  end
end

end
