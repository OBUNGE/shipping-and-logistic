ActiveAdmin.register Shipment do
  # === Strong Parameters ===
  permit_params :order_id, :tracking_number, :status, :carrier, :cost,
                :first_name, :last_name, :address, :alternate_contact,
                :phone_number, :city, :county, :country, :region, :delivery_notes

  # === Index Table ===
  index do
    selectable_column
    id_column
    column :order
    column :tracking_number
    column :status
    column :carrier
    column("Cost") { |shipment| number_to_currency(shipment.cost) }
    column :first_name
    column :last_name
    column :address
    column :city
    column :county
    column :country
    column :region
    column :delivery_notes
    column :created_at
    actions
  end

  # === Filters ===
  filter :order
  filter :status, as: :select, collection: Shipment.statuses.keys
  filter :carrier, as: :select, collection: Shipment.carriers.keys
  filter :phone_number
  filter :city
  filter :country
  filter :region
  filter :created_at

  # === Show Page ===
  show do |shipment|
    attributes_table do
      row :id
      row :order
      row :tracking_number
      row :status
      row :carrier
      row("Cost") { number_to_currency(shipment.cost) }
      row :first_name
      row :last_name
      row :phone_number
      row :alternate_contact
      row :address
      row :city
      row :county
      row :country
      row :region
      row :delivery_notes
      row :created_at
      row :updated_at
    end

    panel "Status Logs" do
      table_for shipment.shipment_status_logs do
        column :status
        column :changed_by_id
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
      f.input :carrier, as: :select, collection: Shipment.carriers.keys
      f.input :cost
      f.input :first_name
      f.input :last_name
      f.input :phone_number
      f.input :alternate_contact
      f.input :address
      f.input :city
      f.input :county
      # ✅ Avoids the country_select plugin error
      f.input :country, as: :string
      f.input :region
      f.input :delivery_notes
    end
    f.actions
  end
end
