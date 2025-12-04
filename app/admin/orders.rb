ActiveAdmin.register Order do
  # === Strong Parameters ===
  permit_params :buyer_id, :seller_id, :status, :total, :provider

  # === Scopes ===
  scope :all, default: true
  scope("Pay on Delivery") { |orders| orders.where(provider: "pod") }
  scope("Prepaid") { |orders| orders.where.not(provider: "pod") }

  # === Index Table ===
  index do
    selectable_column
    id_column
    column :buyer
    column :seller
    column("Total") { |order| number_to_currency(order.total) }
    column :status
    column("Provider") do |order|
      provider_label = order.provider.to_s
      provider_style = provider_label == "pod" ? :warning : :ok
      status_tag(provider_label, provider_style)
    end
    column :created_at
    actions defaults: true do |order|
      if order.provider.to_s == "pod" && order.status == "pending"
        # ✅ Use link_to instead of item
        link_to "Mark as Paid",
                mark_as_paid_admin_order_path(order),
                method: :put,
                class: "member_link"
      end
    end
  end

  # === Filters ===
  filter :buyer, collection: -> { User.all }   # dropdown instead of free-text
  filter :seller, collection: -> { User.all }
  filter :status, as: :select, collection: Order.statuses.keys
  filter :provider, as: :select, collection: ["mpesa", "paypal", "paystack", "pod"]
  filter :total
  filter :created_at

  # === Show Page ===
  show do |order|
    attributes_table do
      row :id
      row :buyer
      row :seller
      row :status
      row :provider
      row("Total") { number_to_currency(order.total) }
      row :created_at
      row :updated_at
    end

    panel "Order Items" do
      table_for order.order_items do
        column :product
        column :quantity
        column("Subtotal") { |item| number_to_currency(item.subtotal) }
      end
    end

    if order.shipment.present?
      panel "Shipment Details" do
        attributes_table_for order.shipment do
          row :carrier
          row :tracking_number
          row :status
          row("Cost") { number_to_currency(order.shipment.cost) }
          row :first_name
          row :last_name
          row :address
          row("Estimated Delivery") do
            order.shipment.estimated_delivery_date&.strftime("%B %d, %Y")
          end
        end
      end
    end
  end

  # === Form ===
  form do |f|
    f.inputs "Order Details" do
      f.input :buyer, collection: User.all
      f.input :seller, collection: User.all
      f.input :status, as: :select, collection: Order.statuses.keys
      f.input :provider, as: :select, collection: ["mpesa", "paypal", "paystack", "pod"]
      f.input :total, min: 0.01  # prevents Formtastic error
    end
    f.actions
  end

  # === Custom Member Action for POD ===
  member_action :mark_as_paid, method: :put do
    resource.update!(status: :paid)
    redirect_to resource_path, notice: "Order marked as paid (cash collected)."
  end
end
