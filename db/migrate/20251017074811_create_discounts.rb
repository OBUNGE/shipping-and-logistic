class CreateDiscounts < ActiveRecord::Migration[8.0]
  def change
    create_table :discounts do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :percentage
      t.boolean :active
      t.datetime :expires_at

      t.timestamps
    end
  end
end
