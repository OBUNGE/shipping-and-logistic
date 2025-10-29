require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Allow Ngrok public tunnel for PayPal callbacks
config.hosts << "df42800c9ea6.ngrok-free.app"

config.action_controller.default_url_options = {
  host: URI.parse(ENV["APP_HOST"] || "http://localhost:3000").host
}

config.action_mailer.default_url_options = {
  host: URI.parse(ENV["APP_HOST"] || "http://localhost:3000").host,
  port: URI.parse(ENV["APP_HOST"] || "http://localhost:3000").port
}

  # Make code changes take effect immediately without server restart.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing.
  config.server_timing = true

  # Enable/disable Action Controller caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = {
      "cache-control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store

  # Store uploaded files locally
  config.active_storage.service = :local

  # Mailer settings
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false

  # Deprecation and migration warnings
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load

  # Verbose logging
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = true

  # View annotations
  config.action_view.annotate_rendered_view_with_filenames = true

  # Security and callbacks
  config.action_controller.raise_on_missing_callback_actions = true

  # Uncomment to allow Action Cable access from any origin
  # config.action_cable.disable_request_forgery_protection = true

  # Uncomment to enable RuboCop autocorrect on generators
  # config.generators.apply_rubocop_autocorrect_after_generate!
end
