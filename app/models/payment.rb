class Payment < ApplicationRecord
  belongs_to :order
  belongs_to :user, optional: true

  # === Status management ===
  enum :status, {
    pending:  "pending",
    paid:     "paid",
    failed:   "failed"
  }, default: "pending"

  # === Validations ===
  validates :amount, presence: true
  validates :provider, presence: true
  validates :checkout_request_id, uniqueness: true, allow_nil: true
  validates :mpesa_receipt_number, uniqueness: true, allow_nil: true
  validates :currency, inclusion: { in: %w[USD KES] }

  # === Ransack (Admin filtering) ===
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id order_id user_id amount provider status
      checkout_request_id mpesa_receipt_number
      created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[order user]
  end
end
