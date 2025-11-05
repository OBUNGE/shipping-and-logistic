class AddDeliveryFieldsToShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :shipments, :first_name, :string
    add_column :shipments, :last_name, :string
    add_column :shipments, :address, :text
    add_column :shipments, :phone_number, :string
  
   add_column :shipments, :country, :string
   add_column :shipments, :county, :string
   add_column :shipments, :city, :string

  end
end
