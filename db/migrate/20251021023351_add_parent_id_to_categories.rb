class AddParentIdToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :parent_id, :integer
  end
end
