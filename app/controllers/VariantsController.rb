class VariantsController < ApplicationController
  before_action :set_variant, only: [:edit, :update, :destroy]

  def new
    @product = Product.find(params[:product_id])
    @variant = @product.variants.build
  end

  def create
    @product = Product.find(params[:product_id])
    @variant = @product.variants.build(variant_params)
    if @variant.save
      redirect_to edit_product_path(@product), notice: "Variant added."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @variant.update(variant_params)
      redirect_to edit_product_path(@variant.product), notice: "Variant updated."
    else
      render :edit
    end
  end

  def destroy
    product = @variant.product
    @variant.destroy
    redirect_to edit_product_path(product), notice: "Variant deleted."
  end

  private

  def set_variant
    @variant = Variant.find(params[:id])
  end

  def variant_params
    params.require(:variant).permit(:name, :value, :price_modifier)
  end
end
