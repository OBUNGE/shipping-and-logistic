class AddMpesaFieldsToPayments < ActiveRecord::Migration[8.0]
  def change
    add_column :payments, :checkout_request_id, :string
    add_column :payments, :mpesa_receipt_number, :string

    add_index :payments, :checkout_request_id, unique: true
    add_index :payments, :mpesa_receipt_number, unique: true
  end
end