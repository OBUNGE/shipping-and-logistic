class AddImageUrlsToVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :variants, :image_urls, :text
  end
end
