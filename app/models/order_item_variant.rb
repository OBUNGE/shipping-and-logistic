class OrderItemVariant < ApplicationRecord
  belongs_to :order_item
  belongs_to :variant

  # === Validations ===

  validates :variant_id, presence: true

  # Prevent duplicate variant assignments for the same order item
  validates :variant_id, uniqueness: { scope: :order_item_id }
end
