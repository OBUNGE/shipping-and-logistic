class CategoriesController < ApplicationController
  def show
    @category = Category.find_by!(slug: params[:id])
    @products = @category.products.includes(:seller).order(created_at: :desc)

    # ✅ Canonical URL for this category
    @canonical_url = category_url(@category)
  end

  def subcategories
    category = Category.find(params[:id])
    render json: category.subcategories.select(:id, :name)
  end
end
