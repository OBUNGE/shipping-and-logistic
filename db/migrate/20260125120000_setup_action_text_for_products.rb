class SetupActionTextForProducts < ActiveRecord::Migration[8.0]
  def change
    # Create ActionText tables
    create_table :action_text_rich_texts do |t|
      t.string :name, null: false
      t.text :body
      t.references :record, null: false, polymorphic: true, index: false

      t.timestamps
    end

    add_index :action_text_rich_texts, [:record_type, :record_id, :name], name: "index_action_text_rich_texts_uniqueness", unique: true

    # Create storage table for uploaded files (if it doesn't exist)
    create_table :active_storage_blobs, if_not_exists: true do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum

      t.timestamps
    end

    add_index :active_storage_blobs, :key, unique: true, if_not_exists: true

    create_table :active_storage_attachments, if_not_exists: true do |t|
      t.string :name, null: false
      t.references :record, polymorphic: true, null: false, index: false
      t.references :blob, null: false

      t.timestamps
    end

    add_index :active_storage_attachments, [:record_type, :record_id, :name], name: "index_active_storage_attachments_uniqueness", unique: true, if_not_exists: true
    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id, if_not_exists: true
  end
end
