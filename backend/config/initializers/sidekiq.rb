# frozen_string_literal: true

# Sidekiq connects to REDIS_URL. Set it explicitly so the server and client agree.
redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

# How long sidekiq-status keeps a job's status in Redis.
status_expiration = 30.minutes.to_i

Sidekiq.configure_server do |config|
  config.redis = redis_config
  Sidekiq::Status.configure_server_middleware config, expiration: status_expiration
  Sidekiq::Status.configure_client_middleware config, expiration: status_expiration
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
  Sidekiq::Status.configure_client_middleware config, expiration: status_expiration
end

# sidekiq-cron loads recurring jobs from config/schedule.yml when Sidekiq starts.
Sidekiq::Cron.configure do |config|
  config.cron_schedule_file = "config/schedule.yml"
end

if Rails.env.development?
  require "sidekiq/web"
  require "sidekiq/cron/web"
  require "sidekiq-status/web"

  # API-only apps have no session middleware; the dashboard needs one for CSRF protection.
  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_sidekiq_session"
end
