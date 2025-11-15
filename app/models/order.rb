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

  before_create :set_default_status
  before_validation :set_default_currency, on: :create

  # === Status helpers ===
  def mark_as_paid!; update!(status: :paid); end
  def mark_as_shipped!; transaction { update!(status: :shipped); shipment&.mark_as_shipped! }; end
  def mark_as_delivered!; transaction { update!(status: :delivered); shipment&.mark_as_delivered! }; end
  def cancel!; update!(status: :cancelled); shipment&.cancel!; end

  # === Currency helpers ===
  # Always store totals in KES, convert only when needed
  def total_in_kes
    if currency == "KES"
      total
    else
      ExchangeRateService.convert(total, from: currency, to: "KES")
    end
  end

  def total_in_usd
    if currency == "USD"
      total
    else
      ExchangeRateService.convert(total, from: "KES", to: "USD")
    end
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  def set_default_currency
    self.currency ||= "KES"
  end

  def buyer_or_guest_present
    if buyer.nil?
      if first_name.blank? || last_name.blank? || phone_number.blank? || address.blank?
        errors.add(:base, "Guest orders must include name, phone number, and address")
      end
    end
  end
end
