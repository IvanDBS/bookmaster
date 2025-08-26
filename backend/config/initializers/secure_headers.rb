SecureHeaders::Configuration.default do |config|
  # Disallow inline scripts/styles by default; allow inline styles temporarily if needed
  api_hosts = ENV.fetch('CORS_ORIGINS', '').split(',').map(&:strip)
  connect_src = ["'self'"] + api_hosts

  config.csp = {
    default_src: ["'self'"],
    script_src: ["'self'", 'https://accounts.google.com', 'https://apis.google.com'],
    style_src: ["'self'", 'https://accounts.google.com', 'https://fonts.googleapis.com'],
    img_src: ["'self'", 'data:', 'https://accounts.google.com'],
    connect_src: connect_src + ['https://accounts.google.com', 'https://oauth2.googleapis.com', 'https://www.googleapis.com'],
    frame_src: ['https://accounts.google.com'],
    object_src: ["'none'"],
    frame_ancestors: ["'none'"], # Защита от clickjacking
    base_uri: ["'self'"],
    form_action: ["'self'"],
    upgrade_insecure_requests: true, # Принудительный HTTPS
    block_all_mixed_content: true, # Блокировка смешанного контента
  }

  config.hsts = "max-age=31536000; includeSubDomains; preload"
  
  # Дополнительные заголовки безопасности
  config.x_content_type_options = "nosniff"
  config.x_frame_options = "DENY"
  config.x_xss_protection = "1; mode=block"
  config.referrer_policy = "strict-origin-when-cross-origin"
end


