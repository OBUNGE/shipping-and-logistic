class AddFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
     # Remove the already-existing ones before adding new ones if needed
    # OR just add only missing columns
    add_reference :payments, :user, null: false, foreign_key: true unless column_exists?(:payments, :user_id)
    add_column :payments, :amount, :decimal, precision: 10, scale: 2 unless column_exists?(:payments, :amount)
    add_column :payments, :status, :integer, default: 0 unless column_exists?(:payments, :status)
    add_column :payments, :transaction_id, :string unless column_exists?(:payments, :transaction_id)
  end
end
