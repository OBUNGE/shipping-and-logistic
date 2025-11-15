class DiscountsController < ApplicationController
  before_action :set_discount, only: [:edit, :update, :destroy]

  def new
    @product = Product.find(params[:product_id])
    @discount = @product.build_discount
  end

def create
  @product = Product.find(params[:product_id])

  # Ensure discount is built in product currency (KES default)
  @discount = @product.build_discount(
    discount_params.merge(
      active: true,
      currency: @product.currency || "KES"
    )
  )

  if @discount.save
    redirect_to edit_product_path(@product), notice: "Discount added."
  else
    # reload product for the form view
    render :new, status: :unprocessable_entity
  end
end

  def edit
    @product = @discount.product
  end

  def update
    if @discount.update(discount_params)
      redirect_to edit_product_path(@discount.product), notice: "Discount updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    product = @discount.product
    @discount.destroy
    redirect_to edit_product_path(product), notice: "Discount removed."
  end

  private

  def set_discount
    @discount = Discount.find(params[:id])
  end

  def discount_params
    params.require(:discount).permit(:percentage, :expires_at)
  end
end
