class AddContactNumberToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :contact_number, :string
  end
end
