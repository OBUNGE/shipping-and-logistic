class AddProviderToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :provider, :string
  end
end
