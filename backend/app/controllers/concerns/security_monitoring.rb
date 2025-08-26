module SecurityMonitoring
  extend ActiveSupport::Concern

  included do
    before_action :log_security_events
    after_action :log_suspicious_activity
  end

  private

  def log_security_events
    # Логируем попытки доступа к защищенным ресурсам
    if suspicious_request?
      Rails.logger.warn "SECURITY: Suspicious request detected - IP: #{request.ip}, Path: #{request.path}, User-Agent: #{request.user_agent}"
    end
    
    # Логируем попытки доступа к админским функциям
    if admin_action? && !current_user&.admin?
      Rails.logger.warn "SECURITY: Unauthorized admin access attempt - User: #{current_user&.id}, IP: #{request.ip}, Path: #{request.path}"
    end

    # Логируем попытки доступа к GDPR функциям
    if gdpr_action? && !current_user
      Rails.logger.warn "SECURITY: Unauthorized GDPR access attempt - IP: #{request.ip}, Path: #{request.path}"
    end

    # Логируем подозрительные User-Agent
    if suspicious_user_agent?
      Rails.logger.warn "SECURITY: Suspicious User-Agent - IP: #{request.ip}, User-Agent: #{request.user_agent}"
    end
  end

  def log_suspicious_activity
    # Логируем подозрительную активность после запроса
    if response.status == 403 || response.status == 401
      Rails.logger.warn "SECURITY: Access denied - IP: #{request.ip}, Path: #{request.path}, Status: #{response.status}, User: #{current_user&.id}"
    end
    
    # Логируем успешные операции с критичными данными
    if critical_operation?
      Rails.logger.info "SECURITY: Critical operation - User: #{current_user&.id}, IP: #{request.ip}, Path: #{request.path}, Method: #{request.method}"
    end

    # Логируем попытки SQL injection
    if sql_injection_attempt?
      Rails.logger.error "SECURITY: SQL injection attempt detected - IP: #{request.ip}, Path: #{request.path}, Params: #{request.params}"
    end

    # Логируем попытки XSS
    if xss_attempt?
      Rails.logger.error "SECURITY: XSS attempt detected - IP: #{request.ip}, Path: #{request.path}, Params: #{request.params}"
    end
  end

  def suspicious_request?
    # Определяем подозрительные запросы
    suspicious_user_agents = [
      'bot', 'crawler', 'spider', 'scraper', 'curl', 'wget',
      'python', 'java', 'perl', 'ruby', 'php', 'go-http-client'
    ]
    
    user_agent = request.user_agent.to_s.downcase
    suspicious_user_agents.any? { |pattern| user_agent.include?(pattern) }
  end

  def suspicious_user_agent?
    user_agent = request.user_agent.to_s.downcase
    suspicious_patterns = [
      'sqlmap', 'nikto', 'nmap', 'masscan', 'dirb', 'gobuster',
      'burp', 'zap', 'w3af', 'acunetix', 'nessus'
    ]
    
    suspicious_patterns.any? { |pattern| user_agent.include?(pattern) }
  end

  def admin_action?
    # Определяем админские действия
    request.path.include?('/admin/') || 
    request.path.include?('/gdpr/') ||
    request.path.include?('/sidekiq')
  end

  def gdpr_action?
    # Определяем GDPR действия
    request.path.include?('/gdpr/')
  end

  def critical_operation?
    # Определяем критические операции
    critical_paths = [
      '/api/v1/bookings',
      '/api/v1/services',
      '/api/v1/users',
      '/api/v1/gdpr'
    ]
    
    critical_paths.any? { |path| request.path.include?(path) } && 
    %w[POST PUT PATCH DELETE].include?(request.method)
  end

  def sql_injection_attempt?
    # Простая проверка на попытки SQL injection
    sql_patterns = [
      'union select', 'drop table', 'delete from', 'insert into',
      'update set', 'alter table', 'create table', 'exec(',
      'execute(', 'script>', 'javascript:', 'vbscript:'
    ]
    
    params_string = request.params.to_s.downcase
    sql_patterns.any? { |pattern| params_string.include?(pattern) }
  end

  def xss_attempt?
    # Простая проверка на попытки XSS
    xss_patterns = [
      '<script', 'javascript:', 'vbscript:', 'onload=',
      'onerror=', 'onclick=', 'onmouseover=', 'alert(',
      'confirm(', 'prompt(', 'eval(', 'document.cookie'
    ]
    
    params_string = request.params.to_s.downcase
    xss_patterns.any? { |pattern| params_string.include?(pattern) }
  end
end
