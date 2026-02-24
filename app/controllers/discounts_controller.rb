class DiscountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_discount, only: [:show, :edit, :update, :destroy]
  before_action :authorize_discount_owner!, only: [:show, :edit, :update, :destroy]

  # GET /discounts/:id
  def show
    @product = @discount.product
  end

  # GET /discounts/new
  def new
    @product = find_product_from_param
    return redirect_to root_path, alert: "❌ Product not found." unless @product

    authorize_seller!(@product)
    @discount = @product.build_discount
  end

  # POST /discounts
  def create
    @product = find_product_from_param
    return redirect_to root_path, alert: "❌ Product not found." unless @product

    authorize_seller!(@product)

    # Default active to true when the form doesn't include the checkbox
    active_flag = if params.dig(:discount, :active).nil?
                    true
                  else
                    discount_params[:active]
                  end

    @discount = @product.build_discount(discount_params.merge(active: active_flag))

    if @discount.save
      redirect_to edit_product_path(@product), notice: "✅ Discount added successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /discounts/:id/edit
  def edit
    @product = @discount.product
    authorize_seller!(@product)
  end

  # PATCH/PUT /discounts/:id
  def update
    @product = @discount.product
    authorize_seller!(@product)

    if @discount.update(discount_params)
      redirect_to edit_product_path(@product), notice: "✅ Discount updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /discounts/:id
  def destroy
    @product = @discount.product
    authorize_seller!(@product)

    begin
      Discount.transaction do
        @discount.destroy!
      end

      respond_to do |format|
        format.html { redirect_to edit_product_path(@product), notice: "✅ Discount removed successfully!" }
        format.turbo_stream { render turbo_stream: turbo_stream.remove("discount_#{@discount.id}") }
      end
    rescue ActiveRecord::RecordNotDestroyed => e
      logger.error "Failed deleting discount=#{@discount.id}: #{e.message}"
      redirect_to edit_product_path(@product), alert: "❌ Could not remove discount. Please try again."
    rescue => e
      logger.error "Unexpected error deleting discount=#{@discount&.id}: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}" 
      redirect_to edit_product_path(@product), alert: "❌ An error occurred while removing the discount."
    end
  end

  private

  def find_product_from_param
    Product.find_by(slug: params[:product_id]) || Product.find_by(id: params[:product_id])
  end

  def set_discount
    @discount = Discount.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "❌ Discount not found."
  end

  def authorize_discount_owner!
    authorize_seller!(@discount.product)
  end

  def authorize_seller!(product)
    if current_user.blank?
      redirect_to new_user_session_path, alert: "❌ You must be logged in."
    elsif current_user != product.seller && !current_user.admin?
      redirect_to root_path, alert: "❌ You don't have permission to manage this product's discount."
    end
  end

  def discount_params
    params.require(:discount).permit(:percentage, :starts_at, :expires_at, :active)
  end
end
