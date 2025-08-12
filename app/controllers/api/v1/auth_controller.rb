class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user!, only: [:profile, :logout]
  
  def register
    user = User.new(user_params)
    
    if user.save
      # В dev сразу логиним пользователя, чтобы выдать JWT и унифицировать ответ с login
      sign_in user
      token = request.env['warden-jwt_auth.token']
      render json: {
        user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
        token: token,
        message: 'Пользователь успешно зарегистрирован'
      }, status: :created
    else
      render_error(code: 'validation_error', message: user.errors.full_messages.join(', '), status: :unprocessable_entity)
    end
  end
  
  def login
    # Поддерживаем оба формата параметров
    email = params[:email] || params.dig(:user, :email)
    password = params[:password] || params.dig(:user, :password)
    
    user = User.find_by(email: email)
    
    if user&.valid_password?(password)
      sign_in user
      token = request.env['warden-jwt_auth.token']
      render json: {
        user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
        token: token,
        message: 'Успешный вход'
      }
    else
      render_error(code: 'invalid_credentials', message: 'Неверный email или пароль', status: :unauthorized)
    end
  end
  
  def profile
    render json: {
      user: current_user.as_json(only: [:id, :email, :first_name, :last_name, :role, :phone, :bio, :address])
    }
  end
  
  def logout
    sign_out current_user
    render json: { message: 'Успешный выход' }
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, 
                                :first_name, :last_name, :phone, :role, :bio, :address)
  end
end
