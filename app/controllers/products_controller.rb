class ProductsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy, :bulk_inventory_upload]

  require "csv"


def index
  @products = Product.includes(:variants, :inventories)
                     .order(created_at: :desc)

  # 🔍 Search by query (title or description)
  if params[:query].present?
    q = "%#{params[:query]}%"
    @products = @products.where("products.title ILIKE ? OR products.description ILIKE ?", q, q)
  end

  # 🏷️ Filter by category (top-level)
  if params[:category].present?
    category = Category.find_by(slug: params[:category], parent_id: nil)
    if category
      # include products in this category + its subcategories
      sub_ids = category.subcategories.pluck(:id)
      @products = @products.where(category_id: [category.id] + sub_ids)
    end
  end

  # 🏷️ Filter by subcategory (child category)
  if params[:subcategory].present?
    subcategory = Category.find_by(slug: params[:subcategory], parent_id: Category.where(slug: params[:category]).pluck(:id))
    if subcategory
      @products = @products.where(category_id: subcategory.id)
    end
  end

  # 📄 Paginate results
  @products = @products.page(params[:page]).per(20)

rescue => e
  Rails.logger.error "🔥 Products#index failed: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  render plain: "Product listing error: #{e.message}", status: 500
end


def show
  @reviews = @product.reviews.order(created_at: :desc).page(params[:page]).per(5)
  @selected_color = params[:color]

  @variant_images =
    if @selected_color.present?
      @product.variants.where(name: "Color", value: @selected_color)
              .flat_map { |variant| Array(variant.image_urls) }
              .select { |url| url.is_a?(String) && url.present? }
    else
      @product.variants
              .flat_map { |variant| Array(variant.image_urls) }
              .select { |url| url.is_a?(String) && url.present? }
    end

  respond_to do |format|
    format.html
    format.json do
      image_url = @variant_images.find { |url| url.is_a?(String) && url.present? } ||
                  view_context.asset_path("placeholder.png")
      render json: { image_url: image_url }
    end
  end
rescue => e
  Rails.logger.error "🔥 Products#show failed: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  render plain: "Product display error: #{e.message}", status: 500
end

  def new
    @product = Product.new
    build_nested_fields(@product)
  end

  def create
    @product = current_user.products.build(product_params.except(:image, :gallery_images, :variants_attributes))

    if params[:product][:image].present?
      @product.image_url = upload_to_supabase(params[:product][:image])
    end

    if @product.save
      import_inventory_csv(@product)
      @product.update(stock: @product.total_inventory) if params[:product][:inventory_csv].present?

      attach_gallery_images(@product)
      attach_variants(@product)

      redirect_to @product, allow_other_host: true, notice: "Product created successfully."
    else
      Rails.logger.debug "❌ Product save failed: #{@product.errors.full_messages}"
      build_nested_fields(@product)
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "🔥 Products#create crashed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render plain: "Product creation error: #{e.message}", status: 500
  end

  def edit
    build_nested_fields(@product)
  end

  def update
    if @product.update(product_params.except(:image, :gallery_images, :variants_attributes))
      import_inventory_csv(@product)
      @product.update(stock: @product.total_inventory) if params[:product][:inventory_csv].present?

      attach_gallery_images(@product)
      attach_variants(@product)

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

  def import_inventory_csv(product)
    file = params[:product][:inventory_csv] || params[:inventory_csv]
    return unless file.respond_to?(:path)

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
    @product = Product.find_by(id: params[:id] || params[:product_id])
    redirect_to products_path, alert: "Product not found" unless @product
  end

  def build_nested_fields(product)
    product.variants.build if product.variants.empty?
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
      :subcategory_id,
      :inventory_csv,
      gallery_images: [],

      variants_attributes: [
        :id,
        :name,
        :value,
        :price_modifier,
        :_destroy,
        variant_images_attributes: [
          :id,
          :image,
          :_destroy
        ]
      ],

      inventories_attributes: [
        :id,
        :location,
        :quantity,
        :_destroy
      ]
    )
  end


def upload_to_supabase(file)
  return unless file.respond_to?(:original_filename) && file.respond_to?(:read)

  raw_filename = "#{SecureRandom.hex}_#{file.original_filename}"
  encoded_filename = URI.encode_www_form_component(raw_filename)

  bucket = ENV["SUPABASE_BUCKET"]
  project_ref = ENV["SUPABASE_ACCESS_KEY_ID"]
  endpoint = "https://#{project_ref}.supabase.co/storage/v1/object/#{bucket}/#{encoded_filename}"

  uri = URI(endpoint)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Put.new(uri)
  request["Authorization"] = "Bearer #{ENV['SUPABASE_SECRET_ACCESS_KEY']}" # ✅ Use API key, not secret access key
  request["Content-Type"] = file.content_type
  request.body = file.read

  response = http.request(request)

  if response.code.to_i == 200
    "https://#{project_ref}.supabase.co/storage/v1/object/public/#{bucket}/#{encoded_filename}"
  else
    Rails.logger.error "Supabase upload failed: #{response.code} - #{response.body}"
    nil
  end
end

def attach_gallery_images(product)
  gallery_images = params[:product][:gallery_images]

  return unless gallery_images.present? && gallery_images.is_a?(Array)

  valid_files = gallery_images.select do |file|
    file.respond_to?(:original_filename) && file.respond_to?(:read)
  end

  urls = valid_files.map do |file|
    begin
      upload_to_supabase(file)
    rescue => e
      Rails.logger.error "Supabase gallery image upload failed: #{e.message}"
      nil
    end
  end.compact

  product.update(gallery_image_urls: urls)
end

def attach_variants(product)
  return unless product_params[:variants_attributes].present?

  product_params[:variants_attributes].to_h.each do |_, variant_data|
    variant = product.variants.create(
      name: variant_data[:name],
      value: variant_data[:value],
      price_modifier: variant_data[:price_modifier]
    )

    next unless variant_data[:variant_images_attributes].present?

    variant_data[:variant_images_attributes].to_h.each do |_, image_data|
      if image_data[:image].present?
        url = upload_to_supabase(image_data[:image])
        variant.variant_images.create(image_url: url) if url.present?
      end
    end
  end
end

end
