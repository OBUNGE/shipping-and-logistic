class ShipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_seller_or_admin, only: [:index]
  before_action :set_order, only: [:create, :show, :edit, :update, :track]
  before_action :set_shipment, only: [:show, :edit, :update, :track]

  # === GET /shipments ===
  def index
    base_scope = current_user.admin? ? Shipment.includes(:order) : Shipment.joins(:order).where(orders: { seller_id: current_user.id })
    @shipments = base_scope

    @shipments = @shipments.where(status: params[:status]) if params[:status].present?

    if params[:query].present?
      query = params[:query].strip
      @shipments = @shipments.where("tracking_number ILIKE ? OR order_id = ?", "%#{query}%", query.to_i)
    end

    if params[:from].present? && params[:to].present?
      @shipments = @shipments.where(created_at: params[:from]..params[:to])
    end
  end

  # === POST /orders/:order_id/shipment ===
  def create
    unless current_user == @order.seller
      redirect_to order_shipment_path(@order), alert: "You are not authorized to create a shipment for this order." and return
    end

    if @order.payment.nil? || @order.payment.status != "paid"
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
      address:    @order.delivery_address,
      cost:       params[:cost]
    )

    if @shipment.save
      log_status_change(@shipment.status)
      # ✅ Redirect to shipment details page instead of order page
      redirect_to order_shipment_path(@order), notice: "Shipment created successfully with #{carrier.upcase}!"
    else
      redirect_to order_shipment_path(@order), alert: "Shipment could not be created."
    end
  end

  # === GET /orders/:order_id/shipment ===
  def show; end

  # === GET /orders/:order_id/shipment/edit ===
  def edit
    redirect_to order_shipment_path(@order), alert: "You are not authorized to edit this shipment." unless current_user == @order.seller
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
      redirect_to order_shipment_path(@order), alert: "You are not authorized to create a shipment for this order."

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
    # ✅ Always land on shipment details page
    redirect_to order_shipment_path(@order)
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
    params.require(:shipment).permit(:carrier, :tracking_number, :cost, :status, :first_name, :last_name, :address)
  end
end
