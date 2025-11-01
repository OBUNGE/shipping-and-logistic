class Subcategory < ApplicationRecord
  has_many :products
  belongs_to :categories
end
