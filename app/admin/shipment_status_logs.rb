# app/admin/shipment_status_logs.rb
ActiveAdmin.register ShipmentStatusLog do
  actions :index, :show

  index do
    selectable_column
    id_column
    column :shipment
    column :status
    column :changed_by
    column :changed_at
    column :created_at
    actions
  end

  filter :shipment
  filter :status
  filter :changed_by
  filter :changed_at
  filter :created_at

  show do
    attributes_table do
      row :shipment
      row :status
      row :changed_by
      row :changed_at
      row :created_at
    end
  end
end
