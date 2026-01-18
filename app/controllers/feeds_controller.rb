require "csv"

class FeedsController < ApplicationController
  # CSV feed for merchants (Google Merchant Center, Facebook Catalog, etc.)
  def feed
    @products = Product.where(published: true).includes(:category)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        "id", "title", "description", "price", "condition", "link",
        "availability", "image_link", "additional_image_link",
        "color", "shipping_weight", "age_group", "gender", "material"
      ]

      @products.each do |product|
        csv << [
          product.id,
          product.title,
          product.description.to_s,
          "#{product.price} #{product.currency || 'KES'}",
          "new",
          product_url(product, host: "tajaone.app", protocol: "https"),
          product.stock.to_i > 0 ? "in_stock" : "out_of_stock",
          product.image_url.presence || "",
          product.gallery_image_urls.join("|"),
          product.try(:color).presence || "Leather",
          product.weight.present? ? "#{product.weight} kg" : "",
          product.try(:age_group).presence || "adult",
          product.try(:gender).presence || "unisex",
          product.category&.name || "Leather Goods"
        ]
      end
    end

    send_data csv_data, 
              filename: "tajaone_merchant_feed_#{Time.current.strftime('%Y%m%d')}.csv",
              type: "text/csv"
  end

  # XML feed for Google Shopping (Merchant Center)
  def google_merchant
    @products = Product.where(published: true).includes(:category)
    response.headers['Content-Type'] = 'application/xml'
  end

  # JSON feed for custom integrations
  def json_feed
    @products = Product.where(published: true).includes(:category)
    
    products_json = @products.map do |product|
      {
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
        currency: product.currency || 'KES',
        url: product_url(product, host: "tajaone.app", protocol: "https"),
        image: product.image_url,
        gallery: product.gallery_image_urls,
        availability: product.stock > 0 ? 'in_stock' : 'out_of_stock',
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

    render json: { 
      store: "Tajaone",
      country: "KE",
      currency: "KES",
      products: products_json,
      generated_at: Time.current.iso8601
    }
  end
end