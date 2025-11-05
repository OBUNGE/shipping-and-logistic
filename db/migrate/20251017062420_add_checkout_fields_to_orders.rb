class AddCheckoutFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :first_name, :string
    add_column :orders, :last_name, :string
    add_column :orders, :address, :text
  end
end
