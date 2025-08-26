# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Read allowed origins from ENV, fallback to local dev defaults. In production, ENV is required.
    if ENV['RAILS_ENV'] == 'production'
      allowed_origins = ENV.fetch('CORS_ORIGINS') { raise 'CORS_ORIGINS must be set in production' }.split(',')
    else
      allowed_origins = ENV.fetch('CORS_ORIGINS', 'http://localhost:3000,http://localhost:8080,http://localhost:5173,http://localhost:5174').split(',')
    end

    origins(*allowed_origins)

    resource '/api/v1/*',
             headers: %w[Authorization Content-Type Accept X-Requested-With Sec-Fetch-Dest Sec-Fetch-Mode Sec-Fetch-Site],
             methods: %i[get post put patch delete options],
             credentials: true,
             max_age: 86400
             
    # Более строгие настройки для админских эндпоинтов
    resource '/api/v1/admin/*',
             headers: %w[Authorization Content-Type Accept X-Requested-With Sec-Fetch-Dest Sec-Fetch-Mode Sec-Fetch-Site],
             methods: %i[get post put patch delete options],
             credentials: true,
             max_age: 3600

    # Google OAuth endpoints with FedCM support
    resource '/api/v1/auth/*',
             headers: %w[Authorization Content-Type Accept X-Requested-With Sec-Fetch-Dest Sec-Fetch-Mode Sec-Fetch-Site Cross-Origin-Embedder-Policy Cross-Origin-Opener-Policy],
             methods: %i[get post put patch delete options],
             credentials: true,
             max_age: 86400,
             expose: %w[Cross-Origin-Embedder-Policy Cross-Origin-Opener-Policy]
  end
end
