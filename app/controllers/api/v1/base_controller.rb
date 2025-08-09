class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!
  
  private
  
  def current_user
    @current_user ||= super
    Rails.logger.info "BaseController#current_user called, result: #{@current_user&.id} (#{@current_user&.role})"
    @current_user
  end
  
  def authenticate_user!
    Rails.logger.info "BaseController#authenticate_user! called, user_signed_in?: #{user_signed_in?}"
    unless user_signed_in?
      render json: { error: 'Необходима авторизация' }, status: :unauthorized
    end
  end
end 