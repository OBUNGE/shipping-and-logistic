Rails.application.configure do
  # Host for URL generation
  config.action_controller.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }

  # Allow this host
  config.hosts << "shipping-and-logistic.onrender.com"

  # Mailer URLs (e.g. Devise links)
  config.action_mailer.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }

  # Production best practices
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # Caching
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store

  # Active Storage (use Supabase S3, not local)
  config.active_storage.service = :tigris

  # Mailer
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false

  # Logging
  config.active_support.deprecation = :notify
  config.active_record.verbose_query_logs = false
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = false
end
