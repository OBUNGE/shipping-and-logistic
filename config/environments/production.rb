require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ✅ Use Supabase for Active Storage
  config.active_storage.service = :supabase

  # ✅ Secret key fallback
  config.secret_key_base = ENV["SECRET_KEY_BASE"] || Rails.application.credentials.secret_key_base

  # ✅ Serve static assets in production (required for CSS/JS)
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present? || ENV['RENDER'].present?
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}"
  }

  # ✅ Performance and caching
  config.enable_reloading = false
  config.eager_load = true
  config.action_controller.perform_caching = true

  # ✅ Error handling
  config.consider_all_requests_local = false

  # ✅ SSL enforcement
  config.force_ssl = true
  config.assume_ssl = true

  # ✅ Logging to STDOUT (for Render) and optionally to file
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # ✅ Correct logger setup
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))

  # ✅ Optional: also log to file (for local debugging)
  file_logger = Logger.new(Rails.root.join("log/production.log"))
  file_logger.level = Logger::DEBUG
 

  # ✅ Healthcheck silence
  config.silence_healthcheck_path = "/up"

  # ✅ Deprecation and schema settings
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # ✅ I18n fallback
  config.i18n.fallbacks = true

  # ✅ Mailer host (update to your actual domain)
  config.action_mailer.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }
end
