class AddEmailToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :email, :string
  end
end
