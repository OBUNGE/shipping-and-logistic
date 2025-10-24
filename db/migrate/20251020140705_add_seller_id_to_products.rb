class AddSellerIdToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :seller_id, :integer
    add_index :products, :seller_id
  end
end
