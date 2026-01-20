class SitemapsController < ApplicationController
  def show
    filename = params[:filename]
    filepath = Rails.root.join("public/sitemaps/#{filename}")
    
    if File.exist?(filepath)
      send_file filepath, type: "application/x-gzip", disposition: "inline"
    else
      render file: "#{Rails.root}/public/404.html", status: :not_found
    end
  end
end
