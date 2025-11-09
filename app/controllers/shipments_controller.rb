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
    unless current_user == @order.seller
      redirect_to order_shipment_path(@order), alert: "You are not authorized to create a shipment for this order." and return
    end

    latest_payment = @order.payments.last
    if latest_payment.nil? || latest_payment.status != "paid"
      redirect_to order_shipment_path(@order), alert: "Shipment can only be created after payment." and return
    end

    carrier = params[:carrier].to_s.strip.downcase.presence || "dhl"
    unless Shipment.carriers.keys.include?(carrier)
      redirect_to order_shipment_path(@order), alert: "Invalid carrier. Only DHL is supported." and return
    end

    @shipment = @order.build_shipment(
      tracking_number: SecureRandom.hex(6).upcase,
      carrier: carrier,
      status: "pending",
      first_name: @order.first_name,
      last_name:  @order.last_name,
      phone_number: @order.phone_number,
      country: @order.country,
      city: @order.city,
      address: @order.address,
      cost: params[:cost]
    )

    if @shipment.save
      redirect_to order_shipment_path(@order), notice: "Shipment created successfully!"
    else
      Rails.logger.debug "Shipment errors: #{@shipment.errors.full_messages}"
      redirect_to order_shipment_path(@order), alert: "Shipment could not be created: #{@shipment.errors.full_messages.join(', ')}"
    end
  end

  # === GET /orders/:order_id/shipment ===
  def show
    # @shipment is set by before_action
  end

  # === GET /orders/:order_id/shipment/edit ===
  def edit
    unless current_user == @order.seller
      redirect_to order_shipment_path(@order), alert: "You are not authorized to edit this shipment."
    end
  end

  # === PATCH/PUT /orders/:order_id/shipment ===
  def update
    if current_user == @order.seller
      if @shipment.update(shipment_params)
        log_status_change(@shipment.status)
        redirect_to order_shipment_path(@order), notice: "Shipment updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end

    elsif current_user == @order.buyer && @shipment.status == "shipped"
      if @shipment.update(status: "delivered")
        @order.mark_as_delivered!
        log_status_change("delivered")
        redirect_to order_shipment_path(@order), notice: "Order marked as delivered. Thank you!"
      else
        redirect_to order_shipment_path(@order), alert: "Could not confirm delivery."
      end

    else
      redirect_to order_shipment_path(@order), alert: "You are not authorized to update this shipment."
    end
  end

  # === POST /orders/:order_id/shipment/track ===
  def track
    unless @shipment.carrier == "dhl"
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
    ShipmentMailer.status_update(@shipment, new_status).deliver_later
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
    params.require(:shipment).permit(
      :carrier, :cost, :address, :first_name, :last_name,
      :phone_number, :country, :city, :status, :tracking_number,
      :alternate_contact, :county, :region, :delivery_notes
    )
  end
end
