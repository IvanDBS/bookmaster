class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @users = User.masters.includes(:services)
    
    if params[:category].present?
      @users = @users.joins(:services).where("LOWER(services.name) LIKE ?", "%#{params[:category].downcase}%")
    end
    
    render json: @users.as_json(
      only: [:id, :first_name, :last_name, :phone, :bio, :address],
      include: { services: { only: [:id, :name, :price, :duration] } }
    )
  end

  def show
    @user = User.masters.find(params[:id])
    render json: @user.as_json(
      only: [:id, :first_name, :last_name, :phone, :bio, :address],
      include: { services: { only: [:id, :name, :price, :duration, :description] } }
    )
  end

  def update
    if current_user.update(user_params)
      render json: current_user.as_json(only: [:id, :email, :first_name, :last_name, :role, :phone, :bio, :address])
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :bio, :address)
  end
end
