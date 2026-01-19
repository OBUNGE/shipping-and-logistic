namespace :feeds do
  desc "Generate product feeds for Google Merchant Center and other platforms"
  task generate: :environment do
    puts "Generating product feeds..."
    
    products = Product.where(published: true).includes(:category)
    products = Product.includes(:category) if products.empty?
    
    # Generate CSV
    csv_file = Rails.root.join("public", "merchant_feed.csv")
    CSV.open(csv_file, "w") do |csv|
      csv << [
        "id", "title", "description", "price", "condition", "link",
        "availability", "image_link", "additional_image_link",
        "color", "shipping_weight", "age_group", "gender", "material"
      ]
      
      products.each do |product|
        csv << [
          product.id,
          product.title,
          product.description.to_s,
          product.price.to_i,
          "new",
          Rails.application.routes.url_helpers.product_url(product, protocol: "https", host: "tajaone.app"),
          product.stock.to_i > 0 ? "in_stock" : "out_of_stock",
          product.image_url.to_s,
          (product.gallery_image_urls&.join("|") || ""),
          "Leather",
          product.weight.to_f > 0 ? "#{product.weight} kg" : "",
          "adult",
          "unisex",
          product.category&.name || "Leather Goods"
        ]
      end
    end
    
    puts "✓ CSV feed saved to #{csv_file}"
    
    # Generate XML
    xml_file = Rails.root.join("public", "google_merchant.xml")
    xml_content = ActionController::Base.new.render_to_string(
      template: "feeds/google_merchant",
      locals: { products: products }
    )
    File.write(xml_file, xml_content)
    puts "✓ XML feed saved to #{xml_file}"
    
    # Generate JSON
    json_file = Rails.root.join("public", "products.json")
    products_json = products.map do |product|
      {
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
        currency: product.currency || 'KES',
        url: Rails.application.routes.url_helpers.product_url(product, protocol: "https", host: "tajaone.app"),
        image: product.image_url,
        gallery: product.gallery_image_urls || [],
        availability: product.stock.to_i > 0 ? 'in_stock' : 'out_of_stock',
        stock: product.stock,
        category: product.category&.name,
        weight: product.weight,
        condition: 'new',
        discount: {
          percentage: product.discount&.percentage,
          expires_at: product.discount&.expires_at
        }
      }
    end
    
    File.write(json_file, JSON.pretty_generate({
      store: "Tajaone",
      country: "KE",
      currency: "KES",
      products: products_json,
      generated_at: Time.current.iso8601
    }))
    
    puts "✓ JSON feed saved to #{json_file}"
    puts "\nFeeds generated successfully!"
  end
end
