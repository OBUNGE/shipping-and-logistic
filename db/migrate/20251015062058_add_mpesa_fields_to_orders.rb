class AddMpesaFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :mpesa_checkout_id, :string
    add_column :orders, :mpesa_receipt, :string
  end
end
