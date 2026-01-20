# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'https://tajaone.app'

# Pick a standard host for the RAILS_ENV
SitemapGenerator::Sitemap.create do
  # Homepage
  add root_path, changefreq: 'weekly', priority: 1.0

  # Products index
  add products_path, changefreq: 'weekly', priority: 0.9

  # Individual products
  Product.find_each do |product|
    add product_path(product), lastmod: product.updated_at, changefreq: 'monthly', priority: 0.8
  end
end

# Ping search engines
SitemapGenerator::Sitemap.ping_search_engines if Rails.env.production?
