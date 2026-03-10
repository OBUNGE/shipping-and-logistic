namespace :feeds do
  desc "Generate product feeds for Google Merchant Center and other platforms"
  task generate: :environment do
    puts "Generating product feeds..."

    products = Product.where(published: true).includes(:category)
    products = Product.includes(:category) if products.empty?

    # Generate CSV for TikTok / Google Merchant
    csv_file = Rails.root.join("public", "merchant_feed.csv")
    CSV.open(csv_file, "w") do |csv|
      csv << [
        "id", "title", "description", "price", "condition", "link",
        "availability", "image_link", "additional_image_link",
        "brand", "product_type", "color", "shipping_weight",
        "age_group", "gender", "material"
      ]

      products.each do |product|
        csv << [
          product.slug || product.id, # use slug to match pixel content_id
          product.title,
          product.description&.to_plain_text.presence || "Premium leather goods from TajaOne",
          "#{product.price.to_f.round(2)} #{product.currency}", # numeric + currency
          "new",
          Rails.application.routes.url_helpers.product_url(product, protocol: "https", host: "tajaone.app"),
          product.stock.to_i > 0 ? "in stock" : "out of stock", # corrected values
          product.image_url.to_s,
          (product.gallery_image_urls&.join("|") || ""),
          "TajaOne", # required brand
          product.category || "Leather Goods", # product_type
          product.color || "Leather",
          product.weight.to_f > 0 ? "#{product.weight} kg" : "",
          product.age_group || "adult",
          product.gender || "unisex",
          "Leather"
        ]
      end
    end

    puts "✓ CSV feed saved to #{csv_file}"

    # Generate XML for Google Merchant (Option 2: assigns)
    xml_file = Rails.root.join("public", "google_merchant.xml")
    xml_content = ApplicationController.renderer.render(
      template: "feeds/google_merchant",
      assigns: { products: products } # 👈 makes @products available in template
    )
    File.write(xml_file, xml_content)
    puts "✓ XML feed saved to #{xml_file}"

    # Generate JSON for internal use / APIs
    json_file = Rails.root.join("public", "products.json")
    products_json = products.map do |product|
      {
        id: product.slug || product.id,
        title: product.title,
        description: product.description&.to_plain_text,
        price: product.price.to_f.round(2),
        currency: product.currency || 'KES',
        url: Rails.application.routes.url_helpers.product_url(product, protocol: "https", host: "tajaone.app"),
        image: product.image_url,
        gallery: product.gallery_image_urls || [],
        availability: product.stock.to_i > 0 ? 'in stock' : 'out of stock',
        stock: product.stock,
        category: product.category,
        weight: product.weight,
        condition: 'new',
        brand: "TajaOne",
        discount: {
          percentage: product.try(:discount)&.percentage,
          expires_at: product.try(:discount)&.expires_at
        }
      }
    end

    File.write(json_file, JSON.pretty_generate({
      store: "TajaOne",
      country: "KE",
      currency: "KES",
      products: products_json,
      generated_at: Time.current.iso8601
    }))

    puts "✓ JSON feed saved to #{json_file}"
    puts "\nFeeds generated successfully!"
  end
end
