class Discount < ApplicationRecord
  belongs_to :product

  validates :percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :expires_at, presence: true

  # 🔎 Active if flagged true and within date range
  def active?
    today = Date.current
    active &&
      (starts_at.nil? || starts_at <= today) &&
      (expires_at.nil? || expires_at >= today)
  end

  # 💸 Calculate discounted price in product currency (KES default)
  def discounted_price
    return product.price unless percentage.present?

    raw_discounted = product.price * (1 - percentage / 100.0)
    ExchangeRateService.convert(raw_discounted, from: product.currency, to: product.currency || "KES")
  end

  # 🛠️ Callback to deactivate expired discounts
  before_save :deactivate_if_expired

  private

  def deactivate_if_expired
    if expires_at.present? && expires_at < Date.current
      self.active = false
    end
  end
end
