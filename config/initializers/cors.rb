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

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: ENV['RAILS_ENV'] == 'production' ? false : true
  end
end
