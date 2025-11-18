class ProductsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_product, only: [
    :show, :edit, :update, :destroy,
    :bulk_inventory_upload,
    :add_variant, :remove_gallery, :remove_variant, :remove_variant_image
  ]

  require "csv"

  # POST /products/:slug/add_variant
  def add_variant
    @variant = @product.variants.build
    @variant.variant_images.build

    respond_to do |format|
      format.turbo_stream # renders app/views/products/add_variant.turbo_stream.erb
      format.html { redirect_to edit_product_path(@product) }
    end
  end

  # DELETE /products/:slug/remove_gallery
  def remove_gallery
    url = params[:url]
    if @product.gallery_image_urls.delete(url)
      @product.save
      respond_to do |format|
        format.turbo_stream # renders app/views/products/remove_gallery.turbo_stream.erb
        format.html { redirect_to @product, notice: "Gallery image removed." }
      end
    else
      redirect_to @product, alert: "Image not found."
    end
  end

  # DELETE /products/:slug/remove_variant/:id
  def remove_variant
    @variant = @product.variants.find(params[:id])
    @variant.destroy
    respond_to do |format|
      format.turbo_stream # renders app/views/products/remove_variant.turbo_stream.erb
      format.html { redirect_to @product, notice: "Variant removed." }
    end
  end

  # DELETE /products/:slug/remove_variant_image/:id
  def remove_variant_image
    @variant_image = VariantImage.find(params[:id])
    @variant = @variant_image.variant
    @variant_image.destroy
    respond_to do |format|
      format.turbo_stream # renders app/views/products/remove_variant_image.turbo_stream.erb
      format.html { redirect_to @product, notice: "Variant image removed." }
    end
  end

  def index
    @products = Product.includes(:variants, :inventories)
                       .order(created_at: :desc)

    if params[:query].present?
      q = "%#{params[:query]}%"
      @products = @products.where("products.title ILIKE ? OR products.description ILIKE ?", q, q)
    end

    if params[:category].present?
      category = Category.find_by(slug: params[:category], parent_id: nil)
      if category
        sub_ids = category.subcategories.pluck(:id)
        @products = @products.where(category_id: [category.id] + sub_ids)
      end
    end

    if params[:subcategory].present?
      parent = Category.find_by(slug: params[:category])
      subcategory = Category.find_by(slug: params[:subcategory], parent_id: parent&.id)
      @products = @products.where(category_id: subcategory.id) if subcategory
    end

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
                .select(&:present?)
      else
        @product.variants.flat_map { |variant| Array(variant.image_urls) }.select(&:present?)
      end

    respond_to do |format|
      format.html
      format.json do
        image_url = @variant_images.find(&:present?) || view_context.asset_path("placeholder.png")
        render json: { image_url: image_url }
      end
    end
  end

  def new
    @product = Product.new
    build_nested_fields(@product)
  end

  def create
    @product = current_user.products.build(product_params)

    if params[:product][:image].present?
      @product.image_url = upload_to_supabase(params[:product][:image])
    end

    if @product.save
      import_inventory_csv(@product) if params[:product][:inventory_csv].present?
      @product.update(stock: @product.total_inventory)

      attach_gallery_images(@product)
      attach_variant_images(@product)

      redirect_to @product, notice: "Product created successfully."
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
    @product = Product.includes(:inventories, :product_images, variants: :variant_images)
                      .find_by!(slug: params[:slug])
    build_nested_fields(@product)
  end

  def update
    if params[:product][:image].present?
      @product.image_url = upload_to_supabase(params[:product][:image])
    end

    if params[:product][:variants_attributes].present?
      params[:product][:variants_attributes].each do |_, attrs|
        if attrs["_destroy"] == "true"
          variant = Variant.find_by(id: attrs["id"])
          if variant&.order_items&.exists?
            variant.update(active: false)
            attrs.delete("_destroy")
          end
        end
      end
    end

    if @product.update(product_params)
      import_inventory_csv(@product) if params[:product][:inventory_csv].present?
      @product.update(stock: @product.total_inventory)

      # ✅ Handle gallery deletions
      if params[:remove_gallery].present?
        remaining = Array(@product.gallery_image_urls) - params[:remove_gallery]
        @product.update(gallery_image_urls: remaining)
      end

      attach_gallery_images(@product)
      attach_variant_images(@product)

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
    slug = params[:slug] || params[:id]
    @product = Product.friendly.find(slug)
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: "Product not found"
  end

   # Helper to generate DOM IDs for Turbo removal
  def dom_id_for_gallery(url)
    "gallery_image_#{Digest::MD5.hexdigest(url)}"
  end

def build_nested_fields(product)
  # Ensure at least one variant exists
  if product.variants.empty?
    variant = product.variants.build(name: "Color") # default to Color
    variant.variant_images.build # prebuild one image field
  else
    # For existing variants, ensure Color has at least one image
    product.variants.each do |variant|
      if variant.name == "Color" && variant.variant_images.empty?
        variant.variant_images.build
      end
    end
  end

  # Ensure at least one inventory record
  product.inventories.build if product.inventories.empty?

  # If you truly have a product_images association
  product.product_images.build if product.respond_to?(:product_images) && product.product_images.empty?
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
      :category_id,
      :subcategory_id,
      :inventory_csv,
      variants_attributes: [
        :id, :name, :value, :price_modifier, :_destroy,
        variant_images_attributes: [:id, :image, :image_url, :_destroy]
      ],
      inventories_attributes: [:id, :location, :quantity, :_destroy],
      product_images_attributes: [:id, :image_url, :_destroy]
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
    request["Authorization"] = "Bearer #{ENV['SUPABASE_SECRET_ACCESS_KEY']}"
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
    gallery_images = params[:gallery_images] || params[:product][:gallery_images]
    return unless gallery_images.present?

    valid_files = Array(gallery_images).select do |file|
      file.respond_to?(:original_filename) && file.respond_to?(:read)
    end

    new_urls = valid_files.map do |file|
      begin
        upload_to_supabase(file)
      rescue => e
        Rails.logger.error "Supabase gallery image upload failed: #{e.message}"
        nil
      end
    end.compact

    # Ensure gallery_image_urls is always an array
    existing_urls = Array(product.gallery_image_urls)
    product.update(gallery_image_urls: existing_urls + new_urls)
  end

  def attach_variant_images(product)
    product.variants.each do |variant|
      variant.variant_images.each do |vi|
        Rails.logger.debug "👉 Processing VariantImage ID=#{vi.id || 'new'}, image=#{vi.image.inspect}, image_url(before)=#{vi.image_url}"

        # Only upload if a new file was provided
        if vi.image.is_a?(ActionDispatch::Http::UploadedFile)
          Rails.logger.debug "📤 Uploading file #{vi.image.original_filename} for VariantImage ID=#{vi.id || 'new'}"

          if (uploaded_url = upload_to_supabase(vi.image))
            vi.update(image_url: uploaded_url)
            Rails.logger.debug "✅ Uploaded successfully: #{uploaded_url}"
          else
            Rails.logger.error "❌ Upload failed for VariantImage ID=#{vi.id || 'new'}"
          end
        else
          Rails.logger.debug "ℹ️ No new file uploaded for VariantImage ID=#{vi.id || 'new'}, keeping existing image_url=#{vi.image_url}"
        end
      end
    end
  end
end
