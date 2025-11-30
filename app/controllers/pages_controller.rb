class PagesController < ApplicationController
  def home
 # Fetch 4-8 products to show on the home page
    @featured_products = Product.limit(8).order("RANDOM()") 
    
    # Or fetch specific categories if you have them
    @bags = Product.where(category_id: 1).limit(4) 
  end
  def about
  end

  def contact
  end

  def return_policy
  end
end
