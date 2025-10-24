class Discount < ApplicationRecord
  belongs_to :product

  validates :percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :expires_at, presence: true

  def active?
    active && Time.current < expires_at
  end
  def active?
  today = Date.today
  (starts_at.nil? || starts_at <= today) && (expires_at.nil? || expires_at >= today)
end

end
