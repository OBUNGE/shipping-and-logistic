class InventoriesController < ApplicationController
  before_action :set_inventory, only: [:edit, :update, :destroy]

  def new
    @product = Product.find(params[:product_id])
    @inventory = @product.inventories.build
  end

  def create
    @product = Product.find(params[:product_id])
    @inventory = @product.inventories.build(inventory_params)
    if @inventory.save
      redirect_to edit_product_path(@product), notice: "Inventory added."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @inventory.update(inventory_params)
      redirect_to edit_product_path(@inventory.product), notice: "Inventory updated."
    else
      render :edit
    end
  end

  def destroy
    product = @inventory.product
    @inventory.destroy
    redirect_to edit_product_path(product), notice: "Inventory deleted."
  end

  private

  def set_inventory
    @inventory = Inventory.find(params[:id])
  end

  def inventory_params
    params.require(:inventory).permit(:location, :quantity)
  end
end
