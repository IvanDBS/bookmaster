class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user!, only: [:profile]
  
  def register
    user = User.new(user_params)
    
    if user.save
      render json: {
        user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
        message: 'Пользователь успешно зарегистрирован'
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def login
    user = User.find_by(email: params[:user][:email])
    
    if user&.valid_password?(params[:user][:password])
      render json: {
        user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
        message: 'Успешный вход'
      }
    else
      render json: { error: 'Неверный email или пароль' }, status: :unauthorized
    end
  end
  
  def profile
    render json: {
      user: current_user.as_json(only: [:id, :email, :first_name, :last_name, :role, :phone, :bio, :address])
    }
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, 
                                :first_name, :last_name, :phone, :role, :bio, :address)
  end
end
