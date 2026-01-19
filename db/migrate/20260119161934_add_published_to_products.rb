class AddPublishedToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :published, :boolean
  end
end
