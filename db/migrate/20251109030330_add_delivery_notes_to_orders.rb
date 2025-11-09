class AddDeliveryNotesToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :delivery_notes, :text
  end
end
