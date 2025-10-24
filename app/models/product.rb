class Product < ApplicationRecord
  # === Associations ===
  belongs_to :seller, class_name: "User", foreign_key: "user_id"
  belongs_to :category, optional: true
  

  has_many :reviews, dependent: :destroy
  has_many :order_items
  has_many :orders, through: :order_items

  has_many :variants, dependent: :destroy
  has_many :inventories, dependent: :destroy
  has_many :product_images, dependent: :destroy
  has_one  :discount, dependent: :destroy
  belongs_to :seller, class_name: "User"
  belongs_to :subcategory,  optional: true


  # variant_images come through variants
  has_many :variant_images, through: :variants

  # === Attachments ===
  has_one_attached  :image
  has_many_attached :gallery_images

  # === Nested Attributes ===
  accepts_nested_attributes_for :variants,
                                allow_destroy: true,
                                reject_if: ->(attrs) { attrs['name'].blank? || attrs['value'].blank? }
  accepts_nested_attributes_for :inventories,
                                allow_destroy: true,
                                reject_if: :all_blank
  accepts_nested_attributes_for :product_images,
                                allow_destroy: true,
                                reject_if: :all_blank
  # ⚠️ Do NOT put accepts_nested_attributes_for :variant_images here,
  # because it's a has_many :through. Instead, put it in Variant model.

  # === Virtual Attributes ===
  attr_accessor :inventory_csv

  # === Validations ===
  validates :title, :price, :stock, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_order, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # === Scopes ===
  scope :available, -> { where("stock > 0") }
  scope :recent,    -> { order(created_at: :desc) }

  # === Searchable Attributes (Ransack) ===
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id title description price stock min_order user_id category
      estimated_delivery_range created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[seller order_items orders reviews variants inventories discount]
  end

  # === Custom Methods ===
  def average_rating
    reviews.average(:rating)&.round(1) || 0.0
  end

  def review_count
    reviews.count
  end

  def rating_distribution
    reviews.group(:rating).count
  end

  def seller_name
    seller.company_name.presence || seller.name.presence || "Unknown Seller"
  end

  def in_stock?
    stock.to_i > 0
  end

  def delivery_estimate
    estimated_delivery_range.presence || "2–5 business days"
  end

  def discounted_price
    return price unless discount&.active?
    price - (price * discount.percentage / 100.0)
  end

  def total_inventory
    inventories.sum(:quantity)
  end

  private

  # Helper to ensure nested fields exist for form building
  def build_nested_fields
    variants.build if variants.empty?
    inventories.build if inventories.empty?
    product_images.build if product_images.empty?
    # variant_images are built through variants
  end
end
