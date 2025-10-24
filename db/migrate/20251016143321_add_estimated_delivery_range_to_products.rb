class AddEstimatedDeliveryRangeToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :estimated_delivery_range, :string
    add_column :products, :shipping_cost, :decimal
    add_column :products, :return_policy, :text
  end
end
