class CreateShipments < ActiveRecord::Migration[7.1]
  def change
    create_table :shipments do |t|
      t.references :order, null: false, foreign_key: true

      t.string  :carrier
      t.string  :tracking_number
      t.decimal :cost, precision: 12, scale: 2
      t.string  :status, default: "pending"   # enum: pending, shipped, delivered

      t.timestamps
    end
  end
end
