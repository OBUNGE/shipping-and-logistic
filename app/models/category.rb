class Category < ApplicationRecord
  has_many :products
  before_validation :generate_slug
  
  has_many :subcategories, class_name: "Category", foreign_key: "parent_id"
  belongs_to :parent, class_name: "Category", optional: true

  private
  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end
end

