ActiveAdmin.register Order do
  permit_params :buyer_id, :seller_id, :status, :total

  # === Index Table ===
  index do
    selectable_column
    id_column
    column :buyer
    column :seller
    column("Total") { |order| number_to_currency(order.total) }
    column :status
    column :created_at
    actions
  end

  # === Filters ===
  filter :buyer
  filter :seller
  filter :status
  filter :total
  filter :created_at

  # === Show Page ===
  show do
    attributes_table do
      row :id
      row :buyer
      row :seller
      row :status
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
          row("Estimated Delivery") { order.shipment.estimated_delivery_date&.strftime("%B %d, %Y") }
        end
      end
    end
  end

  # === Form ===
  form do |f|
    f.inputs "Order Details" do
      f.input :buyer
      f.input :seller
      f.input :status
      f.input :total, min: 0.01  # ✅ Prevents Formtastic error
    end
    f.actions
  end
end
