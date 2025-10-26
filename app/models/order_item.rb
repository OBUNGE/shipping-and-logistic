class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  before_save :calculate_subtotal
  belongs_to :variant, optional: true

  private

  def calculate_subtotal
    self.subtotal = product.price * quantity
  end
end
