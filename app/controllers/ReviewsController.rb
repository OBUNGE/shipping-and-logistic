class ReviewsController < ApplicationController
  before_action :set_product
  before_action :set_review, only: [:edit, :show, :update, :destroy, :vote]
  # 👉 If you want anonymous reviews, remove the line below
  before_action :authenticate_user!, only: [:create, :edit, :update, :destroy, :vote]

  def create
    # 👉 If you want anonymous reviews, drop `.merge(user: current_user)`
    @review = @product.reviews.build(review_params.merge(user: current_user))

    respond_to do |format|
      if @review.save
        ReviewMailer.new_review(@review).deliver_later
        format.html { redirect_to product_path(@product), notice: "Review submitted successfully." }
        format.turbo_stream # renders create.turbo_stream.erb
      else
        format.html do
          flash[:alert] = @review.errors.full_messages.to_sentence
          redirect_to product_path(@product)
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "review_form",
            partial: "reviews/form",
            locals: { product: @product, review: @review }
          )
        end
      end
    end
  end

  def edit; end
  def show; end

  def update
    if @review.user == current_user && @review.update(review_params)
      redirect_to product_path(@product), notice: "Review updated."
    else
      flash[:alert] = @review.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @review.user == current_user
      @review.destroy
      redirect_to product_path(@product), notice: "Review deleted."
    else
      redirect_to product_path(@product), alert: "Unauthorized"
    end
  end

  # 👍 Helpful voting
  def vote
    @review.increment!(:helpful_count)

    respond_to do |format|
      format.turbo_stream # renders vote.turbo_stream.erb
      format.html { redirect_to product_path(@product), notice: "Thanks for your feedback!" }
    end
  end

  private

  def set_product
    @product = Product.find_by!(slug: params[:product_slug] || params[:slug])
  end

  def set_review
    @review = @product.reviews.find(params[:id])
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
