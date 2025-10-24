class Variant < ApplicationRecord
  belongs_to :product
  has_many :variant_images, dependent: :destroy

  # 👇 Add reject_if: :all_blank so empty image slots are ignored
  accepts_nested_attributes_for :variant_images,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :name, :value, presence: true
end
