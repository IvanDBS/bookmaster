class ApplicationController < ActionController::Base
  include ActionController::MimeResponds
  include Devise::Controllers::SignInOut
  include Devise::Controllers::Helpers
  include SecurityMonitoring
  
  # Отключаем CSRF для API запросов
  protect_from_forgery with: :null_session, if: -> { request.format.json? }
  
  # Дополнительная защита от CSRF для API
  before_action :verify_api_authenticity, if: -> { request.format.json? && request.post? }
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ActionController::RoutingError, with: :not_found
  rescue_from ActionController::UnpermittedParameters, with: :bad_request
  
  private
  
  # Enrich lograge payload safely (no PII)
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.request_id
    payload[:user_id] = respond_to?(:current_user) ? current_user&.id : nil
    payload[:ip] = request.ip
    payload[:user_agent] = request.user_agent
  end

  def render_error(code:, message:, status: :bad_request)
    render json: { error: { code: code, message: message } }, status: status
  end

  def not_found(exception)
    render_error(code: 'not_found', message: 'Запись не найдена', status: :not_found)
  end
  
  def forbidden(exception)
    render_error(code: 'forbidden', message: 'Доступ запрещен', status: :forbidden)
  end
  
  def bad_request(exception)
    render_error(code: 'bad_request', message: exception.message, status: :bad_request)
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :role, :bio, :address])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone, :bio, :address])
  end

  def verify_authenticity_token
    # Для API запросов проверяем JWT токен
    return if request.headers['Authorization'].present?
    
    # Для обычных запросов проверяем CSRF токен
    unless verified_request?
      render_error(code: 'forbidden', message: 'CSRF token verification failed', status: :forbidden)
    end
  end

  def verify_api_authenticity
    # Проверяем Origin header для API запросов
    origin = request.headers['Origin']
    return if origin.blank?
    
    allowed_origins = Rails.env.production? ? 
      ENV.fetch('CORS_ORIGINS', '').split(',') : 
      ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:5173']
    
    unless allowed_origins.include?(origin)
      render_error(code: 'forbidden', message: 'Invalid origin', status: :forbidden)
    end
  end

  def authenticate_user_from_jwt!
    token = request.cookies['jwt_token'] || request.headers['Authorization']&.gsub('Bearer ', '')
    
    if token.blank?
      render_error(code: 'unauthorized', message: 'Токен не найден', status: :unauthorized)
      return false
    end
    
    begin
      payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
      user_id = payload[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render_error(code: 'unauthorized', message: 'Недействительный токен', status: :unauthorized)
      return false
    end
  end

  def current_user
    @current_user
  end

  # Валидация входных данных
  def validate_input_params(params, required_fields = [])
    required_fields.each do |field|
      if params[field].blank?
        render_error(code: 'validation_error', message: "Поле #{field} обязательно для заполнения", status: :bad_request)
        return false
      end
    end
    true
  end

  # Санитизация строковых параметров
  def sanitize_string(value, max_length = 255)
    return nil if value.blank?
    value.to_s.strip[0...max_length]
  end

  # Валидация email
  def validate_email(email)
    email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    email_regex.match?(email.to_s)
  end
end
