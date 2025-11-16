class Product < ApplicationRecord
  # === Associations ===
  belongs_to :category, optional: true
  belongs_to :seller, class_name: "User", foreign_key: "user_id"
  belongs_to :subcategory, optional: true

  has_many :reviews, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items
  has_many :variants, dependent: :destroy
  has_many :inventories, dependent: :destroy
  has_many :product_images, dependent: :destroy
  has_one  :discount, dependent: :destroy

  # === Supabase Image Fields ===
  # Store gallery image URLs in a JSON/text column
  serialize :gallery_image_urls, Array

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

  # === Virtual Attributes ===
  attr_accessor :inventory_csv

  # === Validations ===
  validates :title, :price, :stock, presence: true
  validates :title, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_order, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # === Slugging (SEO URLs) ===
  extend FriendlyId
  friendly_id :title, use: :slugged

  def should_generate_new_friendly_id?
    title_changed?
  end

  # === Scopes ===
  scope :available, -> { where("stock > 0") }
  scope :recent,    -> { order(created_at: :desc) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }

  # === Searchable Attributes (Ransack) ===
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id slug title description price stock min_order user_id category_id subcategory_id
      estimated_delivery_range created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[seller order_items orders reviews variants inventories discount]
  end

  # === Supabase Image Accessors ===
  def image_url
    self[:image_url].presence
  end

  def gallery_image_urls
    super || []
  end

  def add_gallery_image(url)
    update(gallery_image_urls: gallery_image_urls + [url])
  end

  def remove_gallery_image(url)
    update(gallery_image_urls: gallery_image_urls - [url])
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

  # === SEO Helpers ===
  def seo_title
    "#{title} | AfriXpress Marketplace"
  end

  def seo_description
    description.to_s.truncate(160)
  end

  def canonical_url
    Rails.application.routes.url_helpers.product_url(self)
  end

  # === Currency Formatting ===
  def formatted_price(view_context)
    view_context.display_price(discounted_price)
  end

  private

  def build_nested_fields
    variants.build if variants.empty?
    inventories.build if inventories.empty?
    product_images.build if product_images.empty?
  end
end
