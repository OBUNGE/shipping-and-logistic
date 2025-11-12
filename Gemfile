source "https://rubygems.org"
source "https://rails-assets.org" do
  gem "rails-assets-bootstrap", "~> 5.2.3"
end


# Authentication and Authorization
gem 'devise'

# For background jobs (for webhooks and shipment updates)
gem 'sidekiq'

# For API requests to M-Pesa, Sendy, etc.
gem 'faraday'

# For pagination in admin/product lists
gem 'kaminari'


gem "ruby-vips"


# For environment variables (API keys)
gem 'dotenv-rails', groups: [:development, :test, :production]


# For money formatting
gem 'money-rails'

# For file uploads (product images, invoices)
gem 'image_processing', '~> 1.2'

gem "pg"


gem "mini_magick"

gem "blazer"


gem "friendly_id", "~> 5.4.0"



gem "highcharts-rails"
gem "lazy_high_charts"
gem "googlecharts"
gem "gon"


gem "chartkick"
gem "groupdate"

gem 'activeadmin'
gem "sassc-rails"

gem 'httparty'
#gem 'africastalking'

gem "paypal-checkout-sdk", "~> 1.0"
gem "aws-sdk-s3", "~> 1.136"

gem 'prawn-table'

gem "sprockets-rails"
gem 'mini_racer'

gem 'prawn'

gem 'geocoder'

gem 'rqrcode'
gem 'bootstrap', '~> 5.2.3'


# Gemfile
gem 'sib-api-v3-sdk'



# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
#gem "propshaft"
# Use sqlite3 as the database for Active Record

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]


group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end
group :development, :test do
  gem 'rspec-rails'
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'
end
group :test do
  gem 'webdrivers'
end


group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
