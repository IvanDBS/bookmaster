class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!
  
  private
  
  def current_user
    @current_user ||= super
  end
  
  def authenticate_user!
    unless user_signed_in?
      render json: { error: 'Необходима авторизация' }, status: :unauthorized
    end
  end
end 