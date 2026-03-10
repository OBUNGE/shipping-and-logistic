namespace :feeds do
  desc "Generate product feeds for Google Merchant Center and other platforms"
  task generate: :environment do
    puts "Generating product feeds..."

    products = Product.where(published: true).includes(:category)
    products = Product.includes(:category) if products.empty?

    # Helper to map categories to Google taxonomy
    def google_category(product)
      case product.category.try(:name)&.downcase
      when /belt/
        "Apparel & Accessories > Clothing Accessories > Belts"
      when /shoe/
        "Apparel & Accessories > Shoes"
      when /bag/, /duffel/, /handbag/
        "Apparel & Accessories > Handbags"
      when /wallet/
        "Apparel & Accessories > Wallets & Money Clips"
      when /keychain/
        "Apparel & Accessories > Jewelry > Keychains"
      else
        "Apparel & Accessories"
      end
    end

    # Generate CSV for TikTok / Google Merchant
    csv_file = Rails.root.join("public", "merchant_feed.csv")
    CSV.open(csv_file, "w") do |csv|
      csv << [
        "id", "title", "description", "price", "condition", "link",
        "availability", "image_link", "additional_image_link",
        "brand", "product_type", "color", "shipping_weight",
        "age_group", "gender", "material", "google_product_category"
      ]

      products.each do |product|
        csv << [
          product.slug || product.id,
          product.title,
          product.description&.to_plain_text.presence || "Premium leather goods from TajaOne",
          "#{sprintf('%.2f', product.price.to_f)} #{product.currency || 'KES'}", # ✅ two decimals
          "new",
          Rails.application.routes.url_helpers.product_url(product, protocol: "https", host: "tajaone.app"),
          product.stock.to_i > 0 ? "in stock" : "out of stock",
          product.image_url.to_s,
          (product.gallery_image_urls&.join("|") || ""),
          "TajaOne",
          product.category.try(:name) || "Leather Goods",
          product.color || "Leather",
          product.weight.to_f > 0 ? "#{product.weight} kg" : "1 kg",
          product.age_group || "adult",
          product.gender || "unisex",
          "Leather",
          google_category(product) # ✅ taxonomy
        ]
      end
    end

    puts "✓ CSV feed saved to #{csv_file}"

    # Generate XML for Google Merchant
    xml_file = Rails.root.join("public", "google_merchant.xml")
    xml_content = ApplicationController.renderer.render(
      template: "feeds/google_merchant",
      assigns: { products: products }
    )
    File.write(xml_file, xml_content)
    puts "✓ XML feed saved to #{xml_file}"

    # Generate JSON for internal use / APIs
    json_file = Rails.root.join("public", "products.json")
    products_json = products.map do |product|
      {
        id: product.slug || product.id,
        title: product.title,
        description: product.description&.to_plain_text.presence || "Premium leather goods from TajaOne",
        price: sprintf('%.2f', product.price.to_f), # ✅ two decimals
        currency: product.currency || 'KES',
        url: Rails.application.routes.url_helpers.product_url(product, protocol: "https", host: "tajaone.app"),
        image: product.image_url,
        gallery: product.gallery_image_urls || [],
        availability: product.stock.to_i > 0 ? 'in stock' : 'out of stock',
        stock: product.stock,
        category: product.category.try(:name) || "Leather Goods",
        google_product_category: google_category(product), # ✅ taxonomy
        weight: product.weight.to_f > 0 ? "#{product.weight} kg" : "1 kg",
        condition: 'new',
        brand: "TajaOne",
        material: "Leather",
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
