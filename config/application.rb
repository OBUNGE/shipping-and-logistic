require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module 
  class Application < Rails::Application
    config.load_defaults 8.0

    # ✅ Use MiniMagick for ActiveStorage variants
    config.active_storage.variant_processor = :mini_magick

    config.autoload_lib(ignore: %w[assets tasks])
  end
end
