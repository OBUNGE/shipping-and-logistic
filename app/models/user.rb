class User < ApplicationRecord
  # === Devise Authentication ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # === Associations ===

  # Products listed by this user (as seller)
  has_many :products, foreign_key: "user_id", inverse_of: :seller, dependent: :destroy

  # Orders placed by this user (as buyer)
  has_many :orders_as_buyer, class_name: "Order", foreign_key: "buyer_id"

  # Orders received by this user (as seller)
  has_many :orders_as_seller, class_name: "Order", foreign_key: "seller_id"

  # Messaging system
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: "receiver_id", dependent: :destroy

  # Other relationships
  has_many :notifications, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :shipments, through: :orders_as_buyer
  has_many :reviews, dependent: :destroy
  has_many :votes
  has_many :reports

  # === Store Branding ===
  def store_banner_url
    self[:store_banner_url].presence
  end

  def store_logo_url
    self[:store_logo_url].presence
  end

  # === Callbacks ===
  before_validation :generate_store_slug, on: :create
  after_initialize :set_default_active_role, if: :new_record?
  after_create :set_default_branding

  # === Role Checks ===
  def buyer?
    roles.include?("buyer")
  end

  def seller?
    roles.include?("seller")
  end

  def admin?
    roles.include?("admin")
  end

  # === Role Switching ===
  def become_buyer!
    update(roles: ["buyer"], active_role: "buyer")
  end

  def become_seller!
    update(roles: ["seller"], active_role: "seller")
  end

  def toggle_active_role!
    active_role == "buyer" ? become_seller! : become_buyer!
  end

  # === Profile Helpers ===
  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def seller_profile_complete?
    company_name.present? &&
      store_logo_url.present? &&
      store_banner_url.present? &&
      store_description.present?
  end

  # === Private Methods ===
  private

  def generate_store_slug
    source = company_name.presence || full_name.presence || email
    self.store_slug ||= source.parameterize if source.present?
  end

  def set_default_active_role
    self.active_role ||= "buyer"
    self.roles = ["buyer"] if roles.blank?
  end

  def set_default_branding
    update_columns(
      store_logo_url: "https://<your-project-ref>.supabase.co/storage/v1/object/public/store-assets/store-logo-placeholder.png",
      store_banner_url: "https://<your-project-ref>.supabase.co/storage/v1/object/public/store-assets/store-banner-placeholder.png"
    )
  end
end
