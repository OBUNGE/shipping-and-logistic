Rails.application.configure do
  # ✅ Host for URL generation (used by Devise, mailers, etc.)
  config.action_controller.default_url_options = {
    host: "shipping-and-logistic.onrender.com",
    protocol: "https"
  }

  # ✅ Allow both Render and localhost for production testing
  config.hosts << "shipping-and-logistic.onrender.com"
  config.hosts << "localhost"
  config.hosts << "www.example.com"

  # ✅ Active Storage (Supabase S3-compatible)
  config.active_storage.service = :supabase

  # ✅ Early boot debug message
  puts "🚀 Booting in #{Rails.env} mode with DB: #{ENV['SUPABASE_DB_URL']}"
  puts "✅ SUPABASE_BUCKET: #{ENV['SUPABASE_BUCKET'].inspect}"
  puts "✅ ActiveStorage service: #{Rails.application.config.active_storage.service.inspect}"
 

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

  # ✅ Mailer delivery settings
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false

  # ✅ Logging
  config.active_support.deprecation = :notify
  config.active_record.verbose_query_logs = false
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = false
end
