class AddGuestTokenToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :guest_token, :string
  end
end
