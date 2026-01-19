class AddGoogleMerchantAttributesToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :color, :string
    add_column :products, :age_group, :string
    add_column :products, :gender, :string
    add_column :products, :size, :string
  end
end
