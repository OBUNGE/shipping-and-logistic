class RenameDeliveryAddressToAddress < ActiveRecord::Migration[8.0]
  def change
     rename_column :orders, :delivery_address, :address
  end
end
