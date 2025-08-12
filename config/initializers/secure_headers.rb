SecureHeaders::Configuration.default do |config|
  # Disallow inline scripts/styles by default; allow inline styles temporarily if needed
  api_hosts = ENV.fetch('CORS_ORIGINS', '').split(',').map(&:strip)
  connect_src = ["'self'"] + api_hosts

  config.csp = {
    default_src: ["'self'"],
    script_src: ["'self'"],
    style_src: ["'self'"],
    img_src: ["'self'", 'data:'],
    connect_src: connect_src,
    object_src: ["'none'"],
    frame_ancestors: ["'self'"],
    base_uri: ["'self'"],
    form_action: ["'self'"],
  }

  config.hsts = "max-age=31536000; includeSubDomains; preload"
end


