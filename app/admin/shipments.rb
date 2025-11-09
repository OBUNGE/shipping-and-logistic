ActiveAdmin.register Shipment do
  permit_params :order_id, :tracking_number, :status, :carrier, :cost,
                :first_name, :last_name, :address, :alternate_contact,
                :phone_number, :city, :county, :country, :region, :delivery_notes

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
    column :address
    column :city
    column :county
    column :country
    column :region
    column :delivery_notes
    column :created_at
    actions
  end

  filter :order
  filter :status, as: :select, collection: Shipment.statuses.keys
  filter :carrier
  filter :phone_number
  filter :city
  filter :country
  filter :region
  filter :created_at

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
  end

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
      f.input :alternate_contact
      f.input :address
      f.input :city
      f.input :county
      f.input :country
      f.input :region
      f.input :delivery_notes
    end
    f.actions
  end
end
