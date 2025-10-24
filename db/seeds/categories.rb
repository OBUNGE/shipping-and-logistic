# Clear existing categories
Category.delete_all

# Define categories and subcategories
categories = {
  "Industrial & Construction" => [
    "Construction machinery",
    "Building materials",
    "Hardware & tools",
    "Safety gear and construction PPEs"
  ],
  "Agriculture & Farming" => [
    "Tractors, harvesters, and planters",
    "Irrigation systems & accessories",
    "Seeds, fertilizers, and agrochemicals",
    "Livestock and poultry equipment"
  ],
  "Transport & Logistics" => [
    "Spare parts and tires",
    "Forklifts and warehouse equipment",
    "Packaging and loading materials"
  ],
  "Office & Business" => [
    "Printers and IT accessories",
    "Office furniture",
    "POS systems and business machines",
    "Stationery and office supplies"
  ],
  "Home & Living" => [
    "Furniture and décor",
    "Lighting and smart home devices",
    "Kitchen appliances",
    "Cleaning and storage supplies"
  ],
  "PPEs (Personal Protective Equipment)" => [
    "Industrial safety helmets, gloves, and boots",
    "Reflective vests and coveralls",
    "Respirators and face shields",
    "Hearing and eye protection"
  ],
  "Textiles & Fashion" => [
    "Clothing, uniforms, and workwear",
    "Shoes, caps, and bags",
    "Fabrics and sewing materials",
    "Embroidery and heat press machines"
  ],
  "Food & Beverages" => [
    "Food processing machines",
    "Beverage and juice filling machines",
    "Packaging machines",
    "Coffee machines and dispensers"
  ],
  "Commercial Kitchen Equipment & Supplies" => [
    "Industrial cookers and ovens",
    "Refrigerators, freezers, and chillers",
    "Stainless steel tables, sinks, and trolleys",
    "Restaurant utensils and small kitchenware"
  ],
  "Electronics & Energy" => [
    "Solar panels, inverters, and batteries",
    "Electrical fittings and cables",
    "Smart devices, routers, CCTV systems",
    "Mobile phones and accessories"
  ],
  "Manufacturing & Production" => [
    "Industrial machinery",
    "Packaging and assembly equipment",
    "Compressors and industrial pumps",
    "Spare parts and bearings"
  ],
  "Automotive" => [
    "Spare parts",
    "Car care products",
    "Garage tools and diagnostic machines",
    "Tires and lubricants"
  ],
  "Consumer Goods" => [
    "Household products",
    "Toys and gifts",
    "Watches, sunglasses, and accessories"
  ]
}

# Seed categories and subcategories
categories.each do |parent_name, sub_names|
  parent = Category.create!(name: parent_name)
  sub_names.each do |sub_name|
    Category.create!(name: sub_name, parent_id: parent.id)
  end
end

puts "✅ Categories and subcategories seeded successfully."
