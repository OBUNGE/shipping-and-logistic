class AddDeliveryFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :first_name, :string
    add_column :orders, :last_name, :string
    add_column :orders, :phone_number, :string
    add_column :orders, :alternate_contact, :string
    add_column :orders, :delivery_address, :text
    add_column :orders, :delivery_notes, :text
    add_column :orders, :country, :string
    add_column :orders, :region, :string
    add_column :orders, :county, :string
    add_column :orders, :city, :string
  end
end
