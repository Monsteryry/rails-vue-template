# Sidekiq connects to REDIS_URL. Set it explicitly so the server and client agree.
redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

Sidekiq.configure_server { |config| config.redis = redis_config }
Sidekiq.configure_client { |config| config.redis = redis_config }

if Rails.env.development?
  require "sidekiq/web"

  # API-only apps have no session middleware; the dashboard needs one for CSRF protection.
  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_sidekiq_session"
end
