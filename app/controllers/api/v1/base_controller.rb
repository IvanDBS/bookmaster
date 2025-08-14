class Api::V1::BaseController < ApplicationController
  before_action :force_json_format
  before_action :authenticate_user!

  private

  def current_user
    @current_user ||= super
    @current_user
  end

  def force_json_format
    request.format = :json
  end

  def authenticate_user!
    return if user_signed_in?
    render_error(code: 'unauthorized', message: 'Необходима авторизация', status: :unauthorized)
  end
end