class AddAlternateContactToShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :shipments, :alternate_contact, :string
  end
end
