class AddShippingToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :shipping, :decimal
  end
end
