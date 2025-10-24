class AddDeliveryFieldsToShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :shipments, :first_name, :string
    add_column :shipments, :last_name, :string
    add_column :shipments, :address, :text
  end
end
