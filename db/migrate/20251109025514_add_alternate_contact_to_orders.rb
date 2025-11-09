class AddAlternateContactToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :alternate_contact, :string
  end
end
