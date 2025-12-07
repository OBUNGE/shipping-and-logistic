require "csv"

class FeedsController < ApplicationController
  def merchant
    @products = Product.all

    # Generate CSV feed
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["id", "title", "description", "price", "condition", "link", "availability", "image_link"]

      @products.each do |product|
        csv << [
          product.id,
          product.title,
          product.description,
          "#{product.base_price} KES",
          "new",
          product_url(product),
          product.manual_stock.to_i > 0 ? "in_stock" : "out_of_stock",
          product.main_image_url
        ]
      end
    end

    send_data csv_data, filename: "merchant_feed.csv"
  end
end
