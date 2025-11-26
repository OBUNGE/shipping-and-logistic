class AddWeightToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :weight, :decimal, precision: 8, scale: 2, null: false, default: 0.0
  end
end
