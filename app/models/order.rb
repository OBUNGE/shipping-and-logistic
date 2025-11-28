class Order < ApplicationRecord
  belongs_to :buyer, class_name: "User", optional: true
  belongs_to :seller, class_name: "User"
  has_many   :order_items, dependent: :destroy
  has_many   :payments, dependent: :destroy
  has_one    :shipment, dependent: :destroy

  accepts_nested_attributes_for :shipment

  validates :seller, presence: true
  validates :total, numericality: { greater_than: 0 }
  validates :currency, inclusion: { in: %w[USD KES] }
  validate  :buyer_or_guest_present
  validate  :pod_only_in_nairobi
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  enum :status, {
    pending:   "pending",
    paid:      "paid",
    shipped:   "shipped",
    delivered: "delivered",
    cancelled: "cancelled",
    failed:    "failed",
    refunded:  "refunded"
  }

  before_create :set_default_status, :set_guest_token
  before_validation :set_default_currency, on: :create

  # === Status helpers ===
  def mark_as_paid!
    update!(status: :paid)
  end

  def mark_as_shipped!
    transaction do
      update!(status: :shipped)
      shipment&.mark_as_shipped!
    end
  end

  def mark_as_delivered!
    transaction do
      update!(status: :delivered)
      shipment&.mark_as_delivered!
    end
  end

  def cancel!
    update!(status: :cancelled)
    shipment&.cancel!
  end

  # === Currency helpers ===
  def total_in_kes
    currency == "KES" ? total : ExchangeRateService.convert(total, from: currency, to: "KES")
  end

  def total_in_usd
    currency == "USD" ? total : ExchangeRateService.convert(total, from: "KES", to: "USD")
  end

  # === Ransack support for ActiveAdmin ===
  def self.ransackable_associations(_auth_object = nil)
    %w[buyer seller order_items payments shipment]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      first_name
      last_name
      email
      phone_number
      contact_number
      alternate_contact
      city
      county
      country
      region
      address
      delivery_notes
      status
      currency
      total
      created_at
      updated_at
      guest_token
      provider
    ]
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  def set_default_currency
    self.currency ||= "KES"
  end

  def set_guest_token
    self.guest_token ||= SecureRandom.hex(10)
  end

  # === Guest validation aligned with provider ===
  def buyer_or_guest_present
    if buyer.nil?
      if first_name.blank? || last_name.blank? || address.blank?
        errors.add(:base, "Guest orders must include name and address")
      end

      case provider
      when "mpesa"
        errors.add(:phone_number, "M-PESA orders must include a phone number") if phone_number.blank?
      when "pod"
        errors.add(:contact_number, "Pay on Delivery orders must include a delivery contact number") if contact_number.blank?
      end
    end
  end

  # === POD validation aligned with JS ===
  def pod_only_in_nairobi
    if provider == "pod"
      county_val = county.to_s.downcase.strip
      city_val   = city.to_s.downcase.strip

      unless county_val == "nairobi" || city_val.include?("nairobi")
        errors.add(:provider, "Pay on Delivery is only available in Nairobi")
      end
    end
  end
end
