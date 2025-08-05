class ApplicationController < ActionController::API
  include Pundit::Authorization
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActionController::ParameterMissing, with: :bad_request
  
  private
  
  def not_found(exception)
    render json: { error: 'Запись не найдена' }, status: :not_found
  end
  
  def forbidden(exception)
    render json: { error: 'Доступ запрещен' }, status: :forbidden
  end
  
  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone, :role, :bio, :address])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone, :bio, :address])
  end
end
