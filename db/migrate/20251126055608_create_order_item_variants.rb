class CreateOrderItemVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :order_item_variants do |t|
      t.references :order_item, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
