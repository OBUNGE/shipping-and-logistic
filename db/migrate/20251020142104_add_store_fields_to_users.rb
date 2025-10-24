class AddStoreFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Only add columns if they don't already exist
    add_column :users, :store_name, :string unless column_exists?(:users, :store_name)
    add_column :users, :store_slug, :string unless column_exists?(:users, :store_slug)
    add_index  :users, :store_slug, unique: true unless index_exists?(:users, :store_slug)
    add_column :users, :store_description, :text unless column_exists?(:users, :store_description)
  end
end
