class AddSubcategoryIdToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :subcategory_id, :integer
  end
end
