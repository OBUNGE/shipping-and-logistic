require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ✅ Use Supabase for Active Storage
  config.active_storage.service = :supabase

  # ✅ Host for ActiveStorage signed URLs
  config.action_controller.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }

  # ✅ Ensure URL helpers (like rails_blob_url) generate full URLs
  Rails.application.routes.default_url_options[:host] = "shipping-and-logistic.onrender.com"

  # ✅ Secret key fallback
  config.secret_key_base = ENV["SECRET_KEY_BASE"] || Rails.application.credentials.secret_key_base

  # ✅ Serve static assets (CSS, JS, images, etc.)
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present? || true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}"
  }

  # ✅ Performance settings
  config.enable_reloading = false
  config.eager_load = true
  config.action_controller.perform_caching = true

  # ✅ Error pages
  config.consider_all_requests_local = false

  # ✅ SSL (important for Render + Supabase signed URLs)
  config.force_ssl = true
  config.assume_ssl = true

  # ✅ Logging configuration
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # STDOUT logger for Render logs
  stdout_logger = Logger.new(STDOUT)
  stdout_logger.formatter = Logger::Formatter.new
  config.logger = ActiveSupport::TaggedLogging.new(stdout_logger)

  # Optional: File logger for debugging (does not break Rails 7)
  begin
    file_logger = Logger.new(Rails.root.join("log/production.log"))
    file_logger.level = Logger::DEBUG
    file_logger.formatter = stdout_logger.formatter

    # Dual logging if broadcast exists
    if ActiveSupport::Logger.respond_to?(:broadcast)
      stdout_logger.extend(ActiveSupport::Logger.broadcast(file_logger))
    end
  rescue => e
    Rails.logger.warn("File logger setup failed: #{e.message}")
  end

  # ✅ Healthcheck silence (Render-friendly)
  config.silence_healthcheck_path = "/up"

  # ✅ Database and schema settings
  config.active_record.dump_schema_after_migration = false
  config.active_support.report_deprecations = false
  config.active_record.attributes_for_inspect = [:id]

  # ✅ I18n fallback
  config.i18n.fallbacks = true

  # ✅ Mailer host (for Devise or ActionMailer)
  config.action_mailer.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }

  # ✅ Active Storage: serve via proxy (for Supabase)
  config.active_storage.resolve_model_to_route = :rails_storage_proxy
end
