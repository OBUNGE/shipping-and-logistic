class VariantImage < ApplicationRecord
  belongs_to :variant

  # Rails will pass the uploaded file here via nested attributes.
  attr_accessor :image

  # Require either a permanent image_url OR a file to upload.
  validates :image_url, presence: true, unless: -> { image.present? }

  # Upload to Supabase after the record is committed
  after_commit :upload_to_supabase, on: :create
  after_commit :upload_to_supabase, on: :update

  private

  def upload_to_supabase
    return if image.nil?

    Rails.logger.info "[VariantImage] Attempting Supabase upload: #{image.original_filename} (#{image.content_type})"

    url = SupabaseService.upload(image)

    if url.present?
      update_column(:image_url, url)  # 🔑 persist permanent URL
      Rails.logger.info "[VariantImage] ✅ Upload successful: #{url}"
    else
      Rails.logger.error "[VariantImage] ❌ Upload failed for #{image.original_filename}"
      errors.add(:image_url, "could not be uploaded to Supabase")
    end
  end
end
