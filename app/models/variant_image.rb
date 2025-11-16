class VariantImage < ApplicationRecord
  # === Associations ===
  belongs_to :variant

  # === Virtual Attribute for File Upload ===
  # This lets Rails accept a file field (:image) in the form
  attr_accessor :image

  # === Validations ===
  # Only require image_url if no file is being uploaded
  validates :image_url, presence: true, unless: -> { image.present? }

  # === Supabase Image Field Accessor ===
  def image_url
    self[:image_url].presence
  end
end
