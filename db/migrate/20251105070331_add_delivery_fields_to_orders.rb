class AddDeliveryFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :country, :string
    add_column :orders, :region, :string
    add_column :orders, :county, :string
    add_column :orders, :city, :string
  end
end
