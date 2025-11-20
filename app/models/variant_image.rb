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
    # SupabaseService.upload should return a permanent URL string.
    # We assign that to image_url so it persists in the DB.
    self.image_url = SupabaseService.upload(image)
  end
end
