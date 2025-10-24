class ReviewsController < ApplicationController
def create
  @product = Product.find(params[:product_id])
  @review = @product.reviews.build(review_params.merge(user: current_user))

  respond_to do |format|
    if @review.save
      format.html { redirect_to product_path(@product), notice: "Review submitted successfully." }
      format.js   # renders create.js.erb
    else
      format.html do
        flash[:alert] = @review.errors.full_messages.to_sentence
        redirect_to product_path(@product)
      end
      format.js { render js: "alert('Error: #{@review.errors.full_messages.to_sentence}');" }
    end
  end
  ReviewMailer.new_review(@review).deliver_later

end
def edit
  @product = Product.find(params[:product_id])
  @review = @product.reviews.find(params[:id])
end
def show
  @product = Product.find(params[:product_id])
  @review = @product.reviews.find(params[:id])
end


def update
  @product = Product.find(params[:product_id])
  @review = @product.reviews.find(params[:id])
  if @review.user == current_user && @review.update(review_params)
    redirect_to product_path(@product), notice: "Review updated."
  else
    flash[:alert] = @review.errors.full_messages.to_sentence
    render :edit, status: :unprocessable_entity
  end
end

def destroy
  @product = Product.find(params[:product_id])
  @review = @product.reviews.find(params[:id])
  if @review.user == current_user
    @review.destroy
    redirect_to product_path(@product), notice: "Review deleted."
  else
    redirect_to product_path(@product), alert: "Unauthorized"
  end
end


  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
