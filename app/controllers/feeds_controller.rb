require "csv"

class FeedsController < ApplicationController
  def feed
    @products = Product.all

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        "id", "title", "description", "price", "condition", "link",
        "availability", "image_link", "additional_image_link",
        "color", "shipping_weight", "age_group", "gender"
      ]

      @products.each do |product|
        csv << [
          product.id,
          product.title,
          product.description.to_s,
          "#{product.price} #{product.currency || 'KES'}",   # price with currency
          "new",                                             # all TAJAONE goods are new
          Rails.application.routes.url_helpers.product_url(product, host: "tajaone.app", protocol: "https"),
          product.stock.to_i > 0 ? "in_stock" : "out_of_stock",
          product.image_url,
          product.gallery_image_urls.join(","),              # optional gallery images
          product.try(:color).presence || "Leather",         # fallback if no color column
          product.weight.present? ? "#{product.weight} kg" : "", # shipping weight
          product.try(:age_group).presence || "adult",       # fallback if no age_group column
          product.try(:gender).presence || "unisex"          # fallback if no gender column
        ]
      end
    end

    response.headers["Content-Type"] = "text/csv"
    render plain: csv_data
  end
end