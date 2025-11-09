ActiveAdmin.register Shipment do
  # === Strong parameters ===
  permit_params :order_id,
                :tracking_number,
                :status,
                :carrier,
                :cost,
                :first_name,
                :last_name,
                :phone_number,
                :country,
                :city,
                :address

  # === Index page ===
  index do
    selectable_column
    id_column
    column :order
    column :tracking_number
    column :status
    column :carrier
    column :cost
    column :first_name
    column :last_name
    column :phone_number
    column :country
    column :city
    column :address
    column :created_at
    actions
  end

  # === Filters ===
  filter :order
  filter :status, as: :select, collection: Shipment.statuses.keys
  filter :carrier
  filter :phone_number
  filter :country
  filter :city
  filter :created_at

  # === Show page ===
  show do
    attributes_table do
      row :id
      row :order
      row :tracking_number
      row :status
      row :carrier
      row :cost
      row :first_name
      row :last_name
      row :phone_number
      row :country
      row :city
      row :address
      row :created_at
      row :updated_at
    end

    panel "Status History" do
      table_for shipment.shipment_status_logs.order(changed_at: :desc) do
        column :status
        column :changed_by
        column :changed_at
      end
    end
  end

  # === Form ===
  form do |f|
    f.inputs "Shipment Details" do
      f.input :order
      f.input :tracking_number
      f.input :status, as: :select, collection: Shipment.statuses.keys
      f.input :carrier
      f.input :cost
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :country
      f.input :city
      f.input :address
    end
    f.actions
  end
end
