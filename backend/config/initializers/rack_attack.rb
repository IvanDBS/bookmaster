class Rack::Attack
  # Rate limiting для API endpoints
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Rate limiting для аутентификации
  throttle('login/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == '/api/v1/auth/login' && req.post?
  end

  # Rate limiting для регистрации
  throttle('register/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/api/v1/auth/register' && req.post?
  end

  # Rate limiting для создания бронирований
  throttle('bookings/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/api/v1/bookings' && req.post?
  end

  # Rate limiting для админских эндпоинтов
  throttle('admin/ip', limit: 100, period: 1.hour) do |req|
    req.ip if req.path.start_with?('/api/v1/admin/')
  end

  # Rate limiting для GDPR операций
  throttle('gdpr/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path.start_with?('/api/v1/gdpr/')
  end

  # Блокировка подозрительных IP
  blocklist('blocklist/ip') do |req|
    # Блокируем IP с большим количеством 4xx ошибок
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 5, findtime: 10.minutes, bantime: 1.hour) do
      req.path.start_with?('/api/') && req.env['rack.attack.response_status'] == 401
    end
  end

  # Блокировка известных ботов и сканеров
  blocklist('blocklist/bots') do |req|
    user_agent = req.user_agent.to_s.downcase
    bot_patterns = [
      'bot', 'crawler', 'spider', 'scraper', 'curl', 'wget',
      'python', 'java', 'perl', 'ruby', 'php', 'go-http-client',
      'masscan', 'nmap', 'sqlmap', 'nikto'
    ]
    
    bot_patterns.any? { |pattern| user_agent.include?(pattern) }
  end

  # Логирование заблокированных запросов
  self.blocklisted_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{error: 'Too many requests'}.to_json]]
  end

  self.throttled_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{error: 'Rate limit exceeded'}.to_json]]
  end
end

# Enable Rack::Attack middleware
Rails.application.config.middleware.use Rack::Attack


