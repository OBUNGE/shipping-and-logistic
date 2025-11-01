class SellersController < ApplicationController
  before_action :set_seller, only: [:show, :edit, :update, :subcategories_for_category]
  before_action :authenticate_user!, only: [:edit, :update]
  before_action :authorize_seller!, only: [:edit, :update]

  # =========================
  # Storefront (public view)
  # =========================
  def show
    if @seller.nil?
      redirect_to root_path, alert: "Seller not found"
      return
    end

    # Base product scope
    @products = @seller.products.includes(:category)

    # Collect only categories/subcategories this seller actually uses
    seller_category_ids = @products.pluck(:category_id).uniq
    top_level_categories = Category.where(id: seller_category_ids, parent_id: nil)

    @categories = top_level_categories.map { |c| [c.name, c.slug] }

    # If category filter applied
    if params[:category].present?
      category = top_level_categories.find_by(slug: params[:category])
      if category
        sub_ids = category.subcategories.pluck(:id)
        @products = @products.where(category_id: [category.id] + sub_ids)
        @subcategories = category.subcategories.where(id: seller_category_ids).map { |s| [s.name, s.slug] }
      else
        @subcategories = []
      end
    else
      @subcategories = []
    end

    # If subcategory filter applied
    if params[:subcategory].present?
      sub = Category.find_by(slug: params[:subcategory])
      @products = @products.where(category_id: sub.id) if sub
    end

    # Sorting
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

  # =========================
  # Dynamic Subcategories (AJAX)
  # =========================
  def subcategories_for_category
    category = Category.find_by(slug: params[:category], parent_id: nil)
    if category
      seller_sub_ids = @seller.products.pluck(:category_id).uniq
      subs = category.subcategories.where(id: seller_sub_ids)
      render json: subs.map { |s| { name: s.name, slug: s.slug } }
    else
      render json: []
    end
  end

  # =========================
  # Storefront Settings (seller only)
  # =========================
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
    params.require(:user).permit(:store_name, :store_description, :store_banner_url, :store_logo_url)
  end
end
