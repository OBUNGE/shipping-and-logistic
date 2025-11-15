class Discount < ApplicationRecord
  belongs_to :product

  validates :percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :expires_at, presence: true

  # Ensure discount is only valid within its date range and marked active
  def active?
    today = Date.current
    active &&
      (starts_at.nil? || starts_at <= today) &&
      (expires_at.nil? || expires_at >= today)
  end

  # Calculate discounted price in product currency (KES default)
  def discounted_price
    return product.price unless percentage.present?

    raw_discounted = product.price * (1 - percentage / 100.0)

    # Normalize into product currency (KES default)
    ExchangeRateService.convert(raw_discounted, from: product.currency, to: product.currency || "KES")
  end
end
