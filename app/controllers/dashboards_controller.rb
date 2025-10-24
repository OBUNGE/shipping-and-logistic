class DashboardsController < ApplicationController
  before_action :authenticate_user!

  # === Buyer Dashboard ===
  def buyer
    # Orders for the current user as buyer
    @orders = current_user
      .orders_as_buyer
      .includes(:order_items, :payment, :shipment, :seller)
      .order(created_at: :desc)
  end

  # === Seller Dashboard ===
  def seller
    # Products the current user is selling
    @products = current_user.products.order(created_at: :desc)

    # Orders where the current user is the seller
    @orders = current_user
      .orders_as_seller
      .includes(:order_items, :buyer, :shipment, :payment)

    # === Analytics data for charts and reports ===

    # Orders count grouped by day (requires groupdate gem)
    @sales_data = @orders.group_by_day(:created_at).count

    # Total revenue from paid orders grouped by day
    @revenue_data = @orders
      .where(status: "paid")
      .group_by_day(:updated_at)
      .sum(:total)

    # Top 5 products by number of order_items sold
    top_product_counts = OrderItem
      .joins(:product, :order)
      .where(orders: { seller_id: current_user.id })
      .group("products.title")
      .count

    @top_products = top_product_counts
      .sort_by { |_title, count| -count }
      .first(5)
  end
end
