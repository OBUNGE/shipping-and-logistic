class CreateInventories < ActiveRecord::Migration[8.0]
  def change
    create_table :inventories do |t|
      t.references :product, null: false, foreign_key: true
      t.string :location
      t.integer :quantity

      t.timestamps
    end
  end
end
