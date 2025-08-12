class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user!
  
  private
  
  def current_user
    @current_user ||= super
    @current_user
  end
  
  def authenticate_user!
    unless user_signed_in?
      render_error(code: 'unauthorized', message: 'Необходима авторизация', status: :unauthorized)
    end
  end
end 