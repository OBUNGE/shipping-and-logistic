# Clear existing categories
Category.destroy_all

# Define categories and subcategories for leather-focused ecommerce
categories = {
  "Leather Bags" => [
    "Men’s Leather Bags",
    "Women’s Leather Handbags",
    "Backpacks & Travel Bags",
    "Laptop & Office Bags"
  ],
  "Men’s Leather Shoes" => [
    "Formal Leather Shoes",
    "Casual Leather Shoes",
    "Boots",
    "Sandals & Loafers"
  ],
  "Women’s Leather Shoes" => [
    "Heels & Pumps",
    "Flats & Sandals",
    "Boots",
    "Casual Leather Shoes"
  ],
  "Leather Accessories" => [
    "Belts",
    "Wallets & Purses",
    "Watch Straps",
    "Key Holders"
  ],
  "Home & Lifestyle" => [
    "Leather Décor",
    "Leather Storage Items",
    "Leather Furniture Accents"
  ],
  "Clothing" => [
    "Leather Jackets",
    "Leather Coats",
    "Leather Pants",
    "Leather Skirts"
  ],
  "Sale & Discounts" => [
    "Clearance Bags",
    "Discounted Shoes",
    "Seasonal Offers"
  ]
}

# Seed categories and subcategories
categories.each do |parent_name, sub_names|
  parent = Category.create!(name: parent_name)
  sub_names.each do |sub_name|
    Category.create!(name: sub_name, parent_id: parent.id)
  end
end

puts "✅ Leather categories and subcategories seeded successfully."