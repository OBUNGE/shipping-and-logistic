class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  before_save :calculate_subtotal

  private

  def calculate_subtotal
    self.subtotal = product.price * quantity
  end
end
