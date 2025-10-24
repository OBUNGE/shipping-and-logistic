class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true

      t.decimal :amount, precision: 12, scale: 2
      t.string  :provider
      t.string  :status, default: "pending"   # enum: pending, paid, failed
      t.string  :transaction_id, index: true  # CheckoutRequestID or MpesaReceipt

      t.timestamps
    end
  end
end
