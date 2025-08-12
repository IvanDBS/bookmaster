class Rack::Attack
  # Throttle login and register endpoints by IP
  throttle('req/auth/login', limit: 10, period: 60) do |req|
    req.ip if req.post? && req.path == '/api/v1/auth/login'
  end

  throttle('req/auth/register', limit: 5, period: 60) do |req|
    req.ip if req.post? && req.path == '/api/v1/auth/register'
  end

  # Throttle public users catalog
  throttle('req/public/users', limit: 60, period: 60) do |req|
    req.ip if req.get? && req.path == '/api/v1/users'
  end

  # Throttle public time slots endpoint
  throttle('req/public/time_slots', limit: 120, period: 60) do |req|
    req.ip if req.get? && req.path == '/api/v1/time_slots/public'
  end

  # Throttle public services listing
  throttle('req/public/services', limit: 120, period: 60) do |req|
    req.ip if req.get? && req.path == '/api/v1/services'
  end
end

# Enable Rack::Attack middleware
Rails.application.config.middleware.use Rack::Attack


