class CreateVariantImages < ActiveRecord::Migration[8.0]
  def change
    create_table :variant_images do |t|
      t.references :variant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
