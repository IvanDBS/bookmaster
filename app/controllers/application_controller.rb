class ApplicationController < ActionController::API
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ActionController::RoutingError, with: :not_found
  
  private
  
  # Enrich lograge payload safely (no PII)
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.request_id
    payload[:user_id] = current_user&.id
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
end
