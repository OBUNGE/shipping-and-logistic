class VariantImage < ApplicationRecord
  belongs_to :variant
  attr_accessor :image

  validates :image_url, presence: true, unless: -> { image.present? }

  before_save :upload_to_supabase, if: -> { image.present? }

  private

  def upload_to_supabase
    self.image_url = SupabaseService.upload(image)
  end
end
