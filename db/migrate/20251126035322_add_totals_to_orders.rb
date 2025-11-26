class AddTotalsToOrders < ActiveRecord::Migration[8.0]
    def change
    add_column :orders, :subtotal, :decimal, precision: 12, scale: 2, default: 0.0, null: false
    add_column :orders, :shipping_total, :decimal, precision: 12, scale: 2, default: 0.0, null: false

  end
end