require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bookmaster
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Устанавливаем целевую таймзону приложения. ActiveRecord продолжит хранить в UTC,
    # но все парсинги через Time.zone будут интерпретироваться в указанной зоне.
    config.time_zone = "Europe/Moscow"
    # Все записи времени в БД (включая тип time) сохраняем в локальной TZ,
    # чтобы исключить смещения при записи '00:00' → '21:00' (UTC-офсет).
    config.active_record.default_timezone = :local
    # Отключаем tz-конвертацию для колонок :time, чтобы хранить и читать HH:MM без смещений
    # (оставляем только :datetime под управление таймзоны)
    config.active_record.time_zone_aware_types = [:datetime]
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Add session middleware for Devise
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    # Use Sidekiq for background jobs (mailers, etc.)
    config.active_job.queue_adapter = :sidekiq

    # Security headers
    config.middleware.use Rack::Attack
    config.middleware.use SecureHeaders::Middleware
  end
end
