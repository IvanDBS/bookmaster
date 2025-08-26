# Sentry configuration for error monitoring
if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    
    # Set traces_sample_rate to 1.0 to capture 100% of transactions for performance monitoring
    config.traces_sample_rate = 0.1
    
    # Filter out sensitive data
    config.before_send = lambda do |event, hint|
      # Remove sensitive data from events
      if event.request
        event.request.data = filter_sensitive_data(event.request.data)
        event.request.headers = filter_sensitive_headers(event.request.headers)
      end
      event
    end
    
    # Set environment
    config.environment = Rails.env
    
    # Enable performance monitoring
    config.enable_tracing = true
    
    # Configure sampling
    config.sample_rate = 1.0
  end
end

private

def filter_sensitive_data(data)
  return data unless data.is_a?(Hash)
  
  sensitive_keys = %w[password password_confirmation token authorization api_key secret]
  
  data.transform_values do |value|
    if value.is_a?(Hash)
      filter_sensitive_data(value)
    elsif sensitive_keys.any? { |key| key.to_s.downcase.include?(key) }
      '[FILTERED]'
    else
      value
    end
  end
end

def filter_sensitive_headers(headers)
  return headers unless headers.is_a?(Hash)
  
  sensitive_headers = %w[authorization x-api-key x-auth-token]
  
  headers.transform_keys do |key|
    if sensitive_headers.any? { |header| key.to_s.downcase.include?(header) }
      '[FILTERED]'
    else
      key
    end
  end
end


