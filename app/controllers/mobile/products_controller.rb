module Mobile
  class ProductsController < ApplicationController
    def index
      @categories = Category.where(parent_id: nil)
      @products = Product.published.available
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
      @products = @products.recent
      @products = @products.page(params[:page]).per(12) if @products.respond_to?(:page)
    end

    def show
      @product = Product.find_by!(slug: params[:id])
      @reviews = @product.reviews.limit(3)
    end

    def categories
      @categories = Category.where(parent_id: nil).includes(:products)
    end
  end
end
