class AddGalleryImageUrlsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :gallery_image_urls, :text, array: true, default: []
  end
end
