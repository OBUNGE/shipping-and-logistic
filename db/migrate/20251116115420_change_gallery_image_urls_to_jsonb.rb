class ChangeGalleryImageUrlsToJsonb < ActiveRecord::Migration[8.0]
  def up
    add_column :products, :gallery_image_urls_tmp, :jsonb, default: []

    execute <<-SQL.squish
      UPDATE products
      SET gallery_image_urls_tmp = to_jsonb(gallery_image_urls)
    SQL

    remove_column :products, :gallery_image_urls
    rename_column :products, :gallery_image_urls_tmp, :gallery_image_urls
  end

  def down
    add_column :products, :gallery_image_urls_tmp, :text, array: true, default: []

    execute <<-SQL.squish
      UPDATE products
      SET gallery_image_urls_tmp = ARRAY(
        SELECT jsonb_array_elements_text(gallery_image_urls)
      )
    SQL

    remove_column :products, :gallery_image_urls
    rename_column :products, :gallery_image_urls_tmp, :gallery_image_urls
  end
end