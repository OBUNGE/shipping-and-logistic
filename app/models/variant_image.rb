class VariantImage < ApplicationRecord
  # === Associations ===
  belongs_to :variant

  # === Supabase Image Field ===
  # Stores the image URL directly
  validates :image_url, presence: true

  # === Custom Accessor ===
  def image_url
    self[:image_url].presence
  end
end
