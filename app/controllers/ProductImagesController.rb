class ProductImagesController < ApplicationController
  def destroy
    image = ProductImage.find(params[:id])
    product = image.product
    image.destroy
    redirect_to edit_product_path(product), notice: "Image deleted."
  end
end
