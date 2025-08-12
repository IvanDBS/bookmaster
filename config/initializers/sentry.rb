if defined?(Sentry)
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = (ENV['SENTRY_TRACES_SAMPLE_RATE'] || 0.0).to_f
    config.profiles_sample_rate = (ENV['SENTRY_PROFILES_SAMPLE_RATE'] || 0.0).to_f
    config.environment = Rails.env
    # Avoid PII in events
    config.send_default_pii = false
  end
end


