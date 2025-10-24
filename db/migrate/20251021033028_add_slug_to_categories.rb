class AddSlugToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :slug, :string
  end
end
