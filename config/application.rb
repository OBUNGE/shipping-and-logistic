require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tajaone   # ✅ Your app namespace must be a constant
  class Application < Rails::Application
    config.load_defaults 8.0

    # ✅ Use MiniMagick for ActiveStorage variants
    config.active_storage.variant_processor = :mini_magick

    # Set the application timezone to match your local time
    config.time_zone = 'Africa/Nairobi'  # Adjust this to your timezone

    # Autoload lib/ but ignore assets and tasks
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
