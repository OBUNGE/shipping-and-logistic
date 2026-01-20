class SitemapsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :index

  def index
    @products = Product.where(status: 'published').order(:created_at)
    
    respond_to do |format|
      format.xml { render :index, layout: false, content_type: 'application/xml' }
    end
  rescue => e
    Rails.logger.error("Sitemap error: #{e.message}")
    render xml: { error: 'Sitemap generation failed' }, status: :internal_server_error
  end
end
