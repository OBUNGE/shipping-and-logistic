class RemoveImageUrlsFromVariants < ActiveRecord::Migration[8.0]
   def change
    remove_column :variants, :image_urls, :text
  end
end
