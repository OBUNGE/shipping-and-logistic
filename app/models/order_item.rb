class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  # Single variant association (legacy support)
  belongs_to :variant, optional: true

  # Multiple variants support (join table)
  has_many :order_item_variants, dependent: :destroy
  has_many :variants, through: :order_item_variants

  before_validation :set_unit_price
  before_save :calculate_subtotal

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  # === Pricing Helpers ===
  def set_unit_price
    # Always calculate using Product#effective_price (handles discounts + variant modifiers)
    if variants.any?
      self.unit_price = product.effective_price(variants)
    else
      self.unit_price = product.effective_price(variant)
    end
  end

  def calculate_subtotal
    self.subtotal = unit_price * quantity
  end

  # === Convenience Methods for Views ===
  def formatted_unit_price(view_context)
    view_context.display_price(unit_price)
  end

  def formatted_subtotal(view_context)
    view_context.display_price(subtotal)
  end

  # === Business Logic Helpers ===
  def original_price
    base = product.price

    if variants.any?
      modifier = variants.sum { |v| v.price_modifier.to_f }
      base + modifier
    else
      modifier = variant&.price_modifier.to_f
      base + modifier
    end
  end

  def discounted?
    product.discount&.active?
  end
end
