# app/controllers/sellers_controller.rb
class SellersController < ApplicationController
  before_action :set_seller, only: [:show, :edit, :update]
  before_action :authenticate_user!, only: [:edit, :update]
  before_action :authorize_seller!, only: [:edit, :update]

def show
  @seller = User.find_by(store_slug: params[:slug])
  if @seller.nil?
    redirect_to root_path, alert: "Seller not found"
    return
  end

  # Only categories and subcategories used by this seller
  @categories = @seller.products.joins(:category).distinct.pluck("categories.name")
  @subcategories = @seller.products.joins(:subcategory).distinct.pluck("subcategories.name")

  # Base product scope
  @products = @seller.products.includes(:category, :subcategory)

  # Apply filters
  if params[:category].present?
    @products = @products.joins(:category).where(categories: { name: params[:category] })
  end

  if params[:subcategory].present?
    @products = @products.joins(:subcategory).where(subcategories: { name: params[:subcategory] })
  end

  # Apply sorting
  case params[:sort]
  when "price_asc"
    @products = @products.order(price: :asc)
  when "price_desc"
    @products = @products.order(price: :desc)
  else
    @products = @products.order(created_at: :desc) # default: newest first
  end

  # Paginate results
  @products = @products.page(params[:page]).per(20)

  # Flag for empty results
  @no_products_found = @products.empty?
end

def subcategories_for_category
  category = Category.find_by(name: params[:category])
  subcategories = category&.subcategories&.pluck(:name) || []
  render json: subcategories
end


  def edit
  end

  def update
    if @seller.update(seller_params)
      redirect_to seller_path(@seller.store_slug), notice: "Store updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_seller
    @seller = User.find_by!(store_slug: params[:slug])
  end

  def authorize_seller!
    redirect_to root_path, alert: "Not authorized" unless @seller == current_user
  end

  def seller_params
    params.require(:user).permit(:store_name, :store_description, :store_banner, :store_logo)
  end
end
