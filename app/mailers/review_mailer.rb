class ReviewMailer < ApplicationMailer
  def new_review(review)
    @review = review
    mail(to: review.product.seller.email, subject: "New review for your product")
  end
end
