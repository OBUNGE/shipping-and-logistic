class Category < ApplicationRecord
  # 🔗 Self-referential association for nested categories
  has_many :subcategories,
           class_name: "Category",
           foreign_key: "parent_id",
           dependent: :destroy

  belongs_to :parent,
             class_name: "Category",
             optional: true

  # 🛍️ Products tied to this category
  has_many :products, dependent: :destroy

  # 🏷️ Generate SEO-friendly slug before validation
  before_validation :generate_slug

  private

  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end
end
