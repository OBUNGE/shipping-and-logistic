ActiveAdmin.register Shipment do
  permit_params :order_id, :tracking_number, :status, :carrier, :cost

  index do
    selectable_column
    id_column
    column :order
    column :tracking_number
    column :status
    column :carrier
    column :cost
    column :created_at
    actions
  end

  filter :order
  filter :status
  filter :carrier
  filter :created_at

  form do |f|
    f.inputs do
      f.input :order
      f.input :tracking_number
      f.input :status, as: :select, collection: Shipment.statuses.keys
      f.input :carrier
      f.input :cost
    end
    f.actions
  end
end
