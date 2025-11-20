class ProductImage < ApplicationRecord
  belongs_to :product

  # Virtual attribute for file upload
  attr_accessor :image

  # Validation: require either a permanent URL or a file
  validates :image_url, presence: true, unless: -> { image.present? }

  # Upload to Supabase if a file is present
  before_create :upload_to_supabase, if: -> { image.present? }
  before_update :upload_to_supabase, if: -> { image.present? }

  private

  def upload_to_supabase
    self.image_url = SupabaseService.upload(image)
  end
end
