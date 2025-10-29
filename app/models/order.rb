class Order < ApplicationRecord
  # === Associations ===
  belongs_to :buyer,  class_name: "User"
  belongs_to :seller, class_name: "User"
  has_many   :order_items, dependent: :destroy
  has_one    :payment,     dependent: :destroy
  has_one    :shipment,    dependent: :destroy
  has_many :payments, dependent: :destroy


  # === Validations ===
  validates :buyer, :seller, presence: true
  validates :total, numericality: { greater_than: 0 }
  validates :delivery_address, presence: true
  validates :currency, inclusion: { in: %w[USD KES] }

  # === Searchable attributes for Ransack (Admin filtering) ===
  def self.ransackable_attributes(_auth_object = nil)
    %w[id status total created_at updated_at buyer_id seller_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[buyer seller order_items payment shipment]
  end

  # === Order status management ===
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

  # === Status update helpers ===
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
  # Store totals in USD internally, convert when needed
  def total_in_usd
    total
  end

  def total_in_kes
    rate = ExchangeRateService.get("USD", "KES")
    return total unless rate
    (total * rate).round(2)
  end

  private

  def set_default_status
    self.status ||= "pending"
  end
end
