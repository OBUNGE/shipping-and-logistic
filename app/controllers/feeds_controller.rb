require "csv"

class FeedsController < ApplicationController
  rescue_from StandardError, with: :render_error
  
  # CSV feed for merchants (Google Merchant Center, Facebook Catalog, etc.)
  def feed
    begin
      @products = Product.where(published: true).includes(:category)
      @products = Product.includes(:category) if @products.empty?
    rescue ActiveRecord::ConnectionNotEstablished
      # If database connection fails, return empty feed
      @products = []
    end

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
          product.price.to_i,
          "new",
          product_url(product, protocol: "https"),
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

    send_data csv_data, 
              filename: "tajaone_merchant_feed_#{Time.current.strftime('%Y%m%d')}.csv",
              type: "text/csv"
  end

  # XML feed for Google Shopping (Merchant Center)
  def google_merchant
    begin
      @products = Product.where(published: true).includes(:category)
      @products = Product.includes(:category) if @products.empty?
    rescue ActiveRecord::ConnectionNotEstablished
      @products = []
    end
    
    response.headers['Content-Type'] = 'application/xml; charset=utf-8'
    render :google_merchant
  end

  # JSON feed for custom integrations
  def json_feed
    begin
      @products = Product.where(published: true).includes(:category)
      @products = Product.includes(:category) if @products.empty?
    rescue ActiveRecord::ConnectionNotEstablished
      @products = []
    end
    
    products_json = @products.map do |product|
      {
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.price,
        currency: product.currency || 'KES',
        url: product_url(product, protocol: "https"),
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

    render json: { 
      store: "Tajaone",
      country: "KE",
      currency: "KES",
      products: products_json,
      generated_at: Time.current.iso8601
    }
  end

  private

  def render_error(exception)
    render json: { error: exception.message, backtrace: exception.backtrace.first(5) }, status: :internal_server_error
  end
end