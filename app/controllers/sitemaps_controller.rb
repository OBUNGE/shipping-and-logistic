class SitemapsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :index

  def index
    @products = Product.where(active: true).order(:created_at)
    @static_pages = [
      { path: root_path, priority: 1.0, changefreq: 'weekly' },
      { path: products_path, priority: 0.9, changefreq: 'weekly' },
    ]

    respond_to do |format|
      format.xml { render :index, layout: false }
    end
  end
end
