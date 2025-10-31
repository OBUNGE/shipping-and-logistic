class AddImageUrlToVariantImages < ActiveRecord::Migration[8.0]
  def change
    add_column :variant_images, :image_url, :string
  end
end
