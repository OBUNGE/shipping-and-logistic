# config/sitemap.rb
SitemapGenerator::Sitemap.default_host = 'https://tajaone.app'
SitemapGenerator::Sitemap.create_index = true  # useful if you grow large

SitemapGenerator::Sitemap.create do
  # Static pages
  add root_path, changefreq: 'weekly', priority: 1.0
  add about_path, changefreq: 'monthly', priority: 0.7
  add contact_path, changefreq: 'monthly', priority: 0.7
  add return_policy_path, changefreq: 'monthly', priority: 0.6

  # Products
  add products_path, changefreq: 'weekly', priority: 0.9
  Product.find_each do |product|
    add product_path(product),
        lastmod: product.updated_at,
        changefreq: 'monthly',
        priority: 0.8
  end

  # Categories
  Category.find_each do |category|
    add category_path(category),
        lastmod: category.updated_at,
        changefreq: 'weekly',
        priority: 0.7
  end

  # Sellers
  User.where("roles @> ARRAY[?]::character varying[]", 'seller').find_each do |seller|
    add seller_path(seller),
        lastmod: seller.updated_at,
        changefreq: 'weekly',
        priority: 0.7
  end

end
