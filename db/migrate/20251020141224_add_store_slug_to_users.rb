class AddStoreSlugToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :store_slug, :string
    add_index :users, :store_slug, unique: true
    add_column :users, :store_name, :string
    add_column :users, :store_description, :text
  end
end
