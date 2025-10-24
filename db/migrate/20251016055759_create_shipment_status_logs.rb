class CreateShipmentStatusLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :shipment_status_logs do |t|
      t.references :shipment, null: false, foreign_key: true
      t.string :status
      t.references :changed_by, null: false, foreign_key: { to_table: :users }
      t.datetime :changed_at

      t.timestamps
    end
  end
end
