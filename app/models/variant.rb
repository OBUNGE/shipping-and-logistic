class Variant < ApplicationRecord
  # === Associations ===
  belongs_to :product
  has_many :variant_images, dependent: :destroy
  has_many :order_items

  # === Nested Image Support ===
  accepts_nested_attributes_for :variant_images,
                                allow_destroy: true,
                                reject_if: :all_blank

  # === Validations ===
  validates :name, :value, presence: true

  # === Soft Delete Support ===
  attribute :active, :boolean, default: true
  scope :active, -> { where(active: true) }

  # === Pricing Logic ===
  def adjusted_price
    product.price + (price_modifier || 0)
  end

  # === Image Helper ===
  def primary_image_url
    variant_images.map(&:image_url).find(&:present?)
  end

  # === Custom Methods ===
  def deactivate!
    update(active: false)
  end

  def active?
    active
  end
end
