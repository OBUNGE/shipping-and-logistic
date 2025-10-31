class AddStoreBrandingToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :store_banner_url, :string
    add_column :users, :store_logo_url, :string
  end
end
