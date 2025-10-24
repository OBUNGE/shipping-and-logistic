class VariantImage < ApplicationRecord
  belongs_to :variant
  has_one_attached :image   # ActiveStorage attachment

  validates :image, presence: true
end
