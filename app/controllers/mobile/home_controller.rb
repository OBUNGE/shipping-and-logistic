module Mobile
  class HomeController < ApplicationController
    def index
      @featured_products = Product.published.available.recent.limit(6)
      @categories = Category.where(parent_id: nil).limit(8)
    end
  end
end
