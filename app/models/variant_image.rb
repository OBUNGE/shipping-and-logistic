class VariantImage < ApplicationRecord
  # === Associations ===
  belongs_to :variant

  # === Virtual Attribute for File Upload ===
  # Rails will pass the uploaded file here via nested attributes.
  attr_accessor :image

  # === Validations ===
  # Require either a permanent image_url OR a file to upload.
  validates :image_url, presence: true, unless: -> { image.present? }

  # === Callbacks ===
  # If a file is present, upload it to Supabase before save.
  before_create :upload_to_supabase, if: -> { image.present? }
  before_update :upload_to_supabase, if: -> { image.present? }

private

def upload_to_supabase
  if image.nil?
    Rails.logger.warn "[VariantImage] No file provided for upload (variant_id=#{variant_id})"
    return
  end

  Rails.logger.info "[VariantImage] Attempting Supabase upload: #{image.original_filename} (#{image.content_type})"

  url = SupabaseService.upload(image)

  if url.present?
    self.image_url = url
    Rails.logger.info "[VariantImage] ✅ Upload successful: #{url}"
  else
    Rails.logger.error "[VariantImage] ❌ Upload failed for #{image.original_filename}"
    errors.add(:image_url, "could not be uploaded to Supabase")
  end
end

end
