require "active_support/core_ext/integer/time"
require "uri"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Cloud Run's local disk is ephemeral. Use `ACTIVE_STORAGE_SERVICE=google` with
  # `ACTIVE_STORAGE_GCS_BUCKET` when a durable production bucket is configured.
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Scheduled care notifications must survive web process restarts.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Brevo delivers production email OTPs and trusted-circle invitations. Keep the
  # credentials in Secret Manager and expose them to Cloud Run as environment variables.
  # Assets are compiled while the Docker image is built, before Cloud Run injects
  # those variables. Permit harmless placeholders only for that build-time task.
  build_time_asset_precompile = ENV["SECRET_KEY_BASE_DUMMY"].present?
  required_runtime_env = lambda do |key, build_time_default|
    ENV.fetch(key) do
      raise KeyError, "key not found: #{key.inspect}" unless build_time_asset_precompile

      build_time_default
    end
  end

  app_url = required_runtime_env.call("APP_URL", "https://goldenly.invalid")
  app_uri = URI.parse(app_url)

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: required_runtime_env.call("SMTP_HOST", "localhost"),
    port: ENV.fetch("SMTP_PORT", "587").to_i,
    domain: ENV.fetch("SMTP_DOMAIN", app_uri.host),
    user_name: required_runtime_env.call("SMTP_USER", "build-time-user"),
    password: required_runtime_env.call("SMTP_PASS", "build-time-password"),
    authentication: :plain,
    enable_starttls_auto: true
  }
  config.action_mailer.default_url_options = { host: app_uri.host, protocol: app_uri.scheme }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
