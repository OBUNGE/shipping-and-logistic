# app/controllers/shipments_controller.rb
class ShipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_seller_or_admin, only: [:index]
  before_action :set_order, only: [:new, :create, :show, :edit, :update, :track]
  before_action :set_shipment, only: [:show, :edit, :update, :track]

  require 'httparty'

  # === GET /shipments ===
  def index
    base_scope = if current_user.admin?
                   Shipment.includes(:order)
                 else
                   Shipment.joins(:order).where(orders: { seller_id: current_user.id })
                 end

    @shipments = base_scope
    @shipments = @shipments.where(status: params[:status]) if params[:status].present?

    if params[:query].present?
      query = params[:query].strip
      @shipments = @shipments.where("tracking_number ILIKE ? OR order_id = ?", "%#{query}%", query.to_i)
    end

    if params[:from].present? && params[:to].present?
      from = Date.parse(params[:from]) rescue nil
      to   = Date.parse(params[:to]) rescue nil
      @shipments = @shipments.where(created_at: from.beginning_of_day..to.end_of_day) if from && to
    end
  end

  # === GET /orders/:order_id/shipment/new ===
  def new
    @shipment = @order.build_shipment
  end

  # === POST /orders/:order_id/shipment ===
  def create
    if params[:shipment].present?
      # Normal flow with form params
      @shipment = @order.build_shipment(shipment_params)
    else
      # Auto-create with defaults (works for prepaid and POD)
      @shipment = @order.build_shipment(
        status: "pending",
        first_name: @order.first_name,
        last_name:  @order.last_name,
        address:    @order.address,
        # ✅ Prefer contact_number, fallback to alternate_contact
        phone_number: @order.contact_number.presence || @order.alternate_contact,
        country:    @order.country,
        city:       @order.city,
        cost:       0.0
      )
    end

    # ✅ Explicitly allow POD orders to create shipments even if not paid yet
    if @order.provider == "pod" || @shipment.save
      Rails.logger.info("✅ Shipment created successfully: #{@shipment.inspect}")
      log_status_change(@shipment.status)

      respond_to do |format|
        format.html { redirect_to order_shipment_path(@order), notice: "Shipment created successfully. You can edit details later." }
        format.turbo_stream { redirect_to order_shipment_path(@order), notice: "Shipment created successfully. You can edit details later." }
      end
    else
      Rails.logger.error("❌ Shipment creation failed: #{@shipment.errors.full_messages.join(', ')}")
      respond_to do |format|
        format.html { redirect_to order_path(@order), alert: "Could not create shipment." }
        format.turbo_stream { redirect_to order_path(@order), alert: "Could not create shipment." }
      end
    end
  end

  # === PATCH/PUT /orders/:order_id/shipment ===
  def update
    Rails.logger.info("🚚 Incoming shipment params: #{params[:shipment].inspect}")
    Rails.logger.info("🔒 Permitted shipment params: #{shipment_params.inspect}")

    if current_user == @order.seller
      if @shipment.update(shipment_params)
        Rails.logger.info("✅ Shipment updated successfully: #{@shipment.inspect}")
        log_status_change(@shipment.status)
        redirect_to order_shipment_path(@order), notice: "Shipment updated successfully."
      else
        Rails.logger.error("❌ Shipment update failed: #{@shipment.errors.full_messages.join(', ')}")
        render :edit, status: :unprocessable_entity
      end

    elsif current_user == @order.buyer && @shipment.status == "in_transit"
      if @shipment.update(status: "delivered")
        @order.mark_as_delivered!
        log_status_change("delivered")
        redirect_to order_shipment_path(@order), notice: "Order marked as delivered. Thank you!"
      else
        Rails.logger.error("❌ Buyer delivery confirmation failed: #{@shipment.errors.full_messages.join(', ')}")
        redirect_to order_shipment_path(@order), alert: "Could not confirm delivery."
      end

    else
      redirect_to order_shipment_path(@order), alert: "You are not authorized to update this shipment."
    end
  end

  # === GET /orders/:order_id/shipment ===
  def show; end

  # === GET /orders/:order_id/shipment/edit ===
  def edit
    unless current_user == @order.seller
      redirect_to order_shipment_path(@order), alert: "You are not authorized to edit this shipment."
    end
  end

  # === POST /orders/:order_id/shipment/track ===
  def track
    unless @shipment.carrier.to_s.downcase == "dhl"
      flash[:alert] = "Only DHL tracking is supported."
      redirect_to order_shipment_path(@order) and return
    end

    result = ShipmentTrackingService.new(@shipment).track
    if result[:status].present?
      @shipment.update(status: result[:status])
      log_status_change(result[:status])
      flash[:notice] = "Shipment updated: #{result[:status].humanize}"
    else
      flash[:alert] = "Tracking failed. Please try again later."
    end
    redirect_to order_shipment_path(@order)
  end

  # === GET /shipments/rates ===
  def rates
    country = params[:country]
    city    = params[:city]

    response = HTTParty.post(
      "https://api-mock.dhl.com/mydhlapi/rates", # replace with live endpoint
      headers: {
        "Content-Type"  => "application/json",
        "DHL-API-Key"   => Rails.application.credentials.dhl[:api_key]
      },
      body: {
        customerDetails: {
          shipperDetails: {
            postalCode: "00100",
            cityName: "Nairobi",
            countryCode: "KE"
          },
          receiverDetails: {
            postalCode: "00000",
            cityName: city,
            countryCode: country
          }
        },
        accounts: [
          { number: Rails.application.credentials.dhl[:account_number], typeCode: "shipper" }
        ],
        productCode: "P", # Express Worldwide
        plannedShippingDateAndTime: Time.now.utc.iso8601,
        unitOfMeasurement: "metric",
        isCustomsDeclarable: false
      }.to_json
    )

    if response.success?
      render json: response.parsed_response
    else
      render json: { error: "Unable to fetch DHL rates" }, status: :bad_request
    end
  end

  private

  def log_status_change(new_status)
    ShipmentStatusLog.create!(
      shipment: @shipment,
      status: new_status,
      changed_by: current_user,
      changed_at: Time.current
    )
    ShipmentEmailJob.perform_later(@shipment.id, new_status)
  end

  def require_seller_or_admin
    unless current_user.admin? || current_user.seller?
      redirect_to root_path, alert: "You are not authorized to view shipments."
    end
  end

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_shipment
    @shipment = @order.shipment
  end

  def shipment_params
    permitted = params.require(:shipment).permit(
      :carrier,
      :tracking_number,
      :cost,
      :status,
      :first_name,
      :last_name,
      :address,
      :alternate_contact,
      :phone_number,
      :city,
      :county,
      :country,
      :region,
      :delivery_notes
    )
    Rails.logger.debug("🔎 shipment_params permitted: #{permitted.inspect}")
    permitted
  end
end
