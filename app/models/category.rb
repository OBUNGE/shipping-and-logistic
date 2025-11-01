class Category < ApplicationRecord
  has_many :subcategories, class_name: "Category", foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Category", optional: true

  has_many :products

  before_validation :generate_slug

  private

  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end
end