class Api::V1::BaseController < ApplicationController
  before_action :force_json_format
  before_action :authenticate_user_from_jwt!

  private

  def force_json_format
    request.format = :json
  end
end