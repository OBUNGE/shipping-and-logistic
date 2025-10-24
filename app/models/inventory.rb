class Inventory < ApplicationRecord
  belongs_to :product

  validates :location, :quantity, presence: true
end
