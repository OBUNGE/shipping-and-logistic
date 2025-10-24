class ProductsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy, :bulk_inventory_upload, :remove_gallery_image]

  require "csv"

  def index
    @products = Product.all
  end

  def show
    @reviews = @product.reviews.order(created_at: :desc).page(params[:page]).per(5)
    @selected_color = params[:color]

    @variant_images =
      if @selected_color.present?
        @product.variants.where(name: "Color", value: @selected_color)
                .includes(:variant_images)
                .map(&:variant_images).flatten
      else
        @product.variant_images
      end

    respond_to do |format|
      format.html
      format.json do
        image = @variant_images.first
        render json: {
          image_url: image.present? ? url_for(image.image) : view_context.asset_path("placeholder.png")
        }
      end
    end
  end

  def new
    @product = Product.new
    build_nested_fields(@product)
  end

  def create
    @product = current_user.products.build(product_params)

    if @product.save
      import_inventory_csv(@product)
      @product.update(stock: @product.total_inventory) if params[:product][:inventory_csv].present?
      redirect_to @product, notice: "Product created successfully."
    else
      Rails.logger.debug "❌ Product save failed: #{@product.errors.full_messages}"
      build_nested_fields(@product)
      render :new, status: :unprocessable_entity
    end
    Rails.logger.debug "👤 current_user: #{current_user.inspect}"

  end

 def edit
  build_nested_fields(@product)
end

  def update
    if @product.update(product_params)
      import_inventory_csv(@product)
      @product.update(stock: @product.total_inventory) if params[:product][:inventory_csv].present?
      redirect_to @product, notice: "Product updated successfully."
    else
      Rails.logger.debug "❌ Product update failed: #{@product.errors.full_messages}"
      build_nested_fields(@product)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product deleted."
  end

  def bulk_inventory_upload
    if params[:inventory_csv].present?
      import_inventory_csv(@product)
      @product.update(stock: @product.total_inventory)
      redirect_to edit_product_path(@product), notice: "Inventory uploaded successfully."
    else
      redirect_to edit_product_path(@product), alert: "Please select a CSV file."
    end
  end

  def remove_gallery_image
    image = @product.gallery_images.find_by_id(params[:image_id])
    if image
      image.purge
      redirect_to edit_product_path(@product), notice: "Image removed."
    else
      redirect_to edit_product_path(@product), alert: "Image not found."
    end
  end

  def import_inventory_csv(product)
  file = params[:product][:inventory_csv] || params[:inventory_csv]
  return unless file.respond_to?(:path) # ✅ only proceed if it's a real file

  errors = []
  CSV.foreach(file.path, headers: true).with_index(2) do |row, line|
    location = row["location"]
    quantity = row["quantity"]

    if location.blank? || quantity.blank?
      errors << "Line #{line}: Missing location or quantity"
      next
    end

    unless quantity.to_s =~ /^\d+$/
      errors << "Line #{line}: Quantity must be a whole number"
      next
    end

    product.inventories.create(location: location.strip, quantity: quantity.to_i)
  end

  if errors.any?
    flash[:alert] = "Inventory import completed with errors:\n#{errors.join("\n")}"
  else
    flash[:notice] = "Inventory imported successfully"
  end
end


  private

def set_product
  @product = Product.find(params[:id] || params[:product_id])
end


  def build_nested_fields(product)
    product.variants.build if product.variants.empty?

    # For each Color variant, ensure it has an image slot
    product.variants.select { |v| v.name == "Color" }.each do |color_variant|
      color_variant.variant_images.build if color_variant.variant_images.empty?
    end

    product.inventories.build if product.inventories.empty?
    10.times { product.variants.build } if product.variants.empty?
  end

 def product_params
  params.require(:product).permit(
    :title,
    :description,
    :price,
    :shipping_cost,
    :min_order,
    :stock,
    :estimated_delivery_range,
    :return_policy,
    :image,
    :category_id,
    :subcategory_id, # ✅ newly added
    :inventory_csv,
    gallery_images: [],
    product_images_attributes: [:id, :image, :caption, :_destroy],
    variants_attributes: [
      :id, :name, :value, :price_modifier, :_destroy,
      variant_images_attributes: [:id, :variant_id, :image, :_destroy]
    ],
    inventories_attributes: [:id, :location, :quantity, :_destroy]
  )
end

end
