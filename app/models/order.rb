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

  def mark_as_paid!; update!(status: :paid); end
  def mark_as_shipped!; transaction { update!(status: :shipped); shipment&.mark_as_shipped! }; end
  def mark_as_delivered!; transaction { update!(status: :delivered); shipment&.mark_as_delivered! }; end
  def cancel!; update!(status: :cancelled); shipment&.cancel!; end

  def total_in_usd; total; end
  def total_in_kes
    rate = ExchangeRateService.get("USD", "KES")
    return total unless rate
    (total * rate).round(2)
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  def buyer_or_guest_present
    if buyer.nil?
      if first_name.blank? || last_name.blank? || phone_number.blank? || address.blank?
        errors.add(:base, "Guest orders must include name, phone number, and address")
      end
    end
  end
end
