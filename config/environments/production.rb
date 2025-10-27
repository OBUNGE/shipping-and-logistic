Rails.application.configure do
  # ✅ Fix for allow_browser crash

  # ✅ Host for URL generation (used by Devise, mailers, etc.)
  config.action_controller.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }

  # ✅ Allow both Render and localhost for production testing
  config.hosts << "shipping-and-logistic.onrender.com"
  config.hosts << "localhost"

  # ✅ Mailer URLs (used by Devise, password reset, etc.)
  config.action_mailer.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }

  # ✅ Production best practices
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # ✅ Caching
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store

  # ✅ Active Storage (Supabase S3-compatible)
  config.active_storage.service = :supabase

  # ✅ Mailer delivery settings
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false

  # ✅ Logging
  config.active_support.deprecation = :notify
  config.active_record.verbose_query_logs = false
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = false
end
