class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user!, only: [:profile, :logout]
  
  def register
    user = User.new(user_params)
    
    if user.save
      # Отправляем письмо подтверждения (асинхронно через ActiveJob/Sidekiq)
      user.send_confirmation_instructions
      render json: {
        user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
        message: 'Пользователь успешно зарегистрирован. Проверьте почту для подтверждения учетной записи.'
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
      unless user.confirmed?
        return render_error(code: 'unconfirmed', message: 'Email не подтвержден. Проверьте почту или запросите повторное письмо.', status: :unauthorized)
      end
      sign_in user, store: false
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

  def confirm
    token = params[:confirmation_token]
    return render_error(code: 'bad_request', message: 'Отсутствует confirmation_token', status: :bad_request) if token.blank?

    user = User.confirm_by_token(token)
    if user.errors.empty?
      render json: { message: 'Email успешно подтвержден' }
    else
      render_error(code: 'invalid_token', message: user.errors.full_messages.join(', '), status: :unprocessable_entity)
    end
  end

  def resend_confirmation
    email = params[:email]
    return render_error(code: 'bad_request', message: 'Отсутствует email', status: :bad_request) if email.blank?

    user = User.find_by(email: email)
    if user.nil?
      return render json: { message: 'Если пользователь существует, письмо будет отправлено' }
    end

    if user.confirmed?
      return render json: { message: 'Email уже подтвержден' }
    end

    user.resend_confirmation_instructions
    render json: { message: 'Письмо с подтверждением отправлено' }
  end
  
  # Google Sign-In via ID token (Google Identity Services)
  def google
    id_token = params[:id_token]
    return render_error(code: 'bad_request', message: 'Missing id_token', status: :bad_request) if id_token.blank?

    begin
      payload = verify_google_id_token(id_token)
      email = payload['email']
      first_name = payload['given_name']
      last_name = payload['family_name']

      unless payload['email_verified']
        return render_error(code: 'unauthorized', message: 'Email не подтвержден Google', status: :unauthorized)
      end

      user = User.find_by(email: email)
      if user.nil?
        # Создаем минимального пользователя как client по умолчанию
        # Обходим требование phone для OAuth-профиля: ставим временное значение
        user = User.new(
          email: email,
          password: SecureRandom.hex(16),
          first_name: first_name.presence || 'Google',
          last_name: last_name.presence || 'User',
          role: 'client',
          phone: '+0000000000'
        )
        unless user.save
          # Если всё равно не сохранился — вернем понятную ошибку
          return render_error(code: 'validation_error', message: user.errors.full_messages.join(', '), status: :unprocessable_entity)
        end
      end

      sign_in user, store: false
      token = request.env['warden-jwt_auth.token']
      if token.blank?
        begin
          require 'warden/jwt_auth'
          encoder = Warden::JWTAuth::UserEncoder.new
          token, _payload = encoder.call(user, :user, nil)
        rescue StandardError => e
          Rails.logger.error("manual JWT encode failed: #{e.message}")
        end
      end
      response.set_header('Authorization', "Bearer #{token}") if token.present?
      render json: {
        user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
        token: token,
        message: 'Успешный вход через Google'
      }
    rescue StandardError => e
      render_error(code: 'unauthorized', message: e.message, status: :unauthorized)
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

  # Упрощенная валидация через официальную конечную точку tokeninfo (подходит для dev)
  # В продакшне можно перейти на проверку подписи через JWKS
  def verify_google_id_token(id_token)
    require 'net/http'
    require 'uri'
    require 'json'

    uri = URI.parse("https://oauth2.googleapis.com/tokeninfo?id_token=#{CGI.escape(id_token)}")
    res = Net::HTTP.get_response(uri)
    raise 'Не удалось проверить токен Google' unless res.is_a?(Net::HTTPSuccess)
    payload = JSON.parse(res.body)

    # Проверяем audience и issuer
    aud_ok = payload['aud'] == google_client_id
    iss_ok = ['https://accounts.google.com', 'accounts.google.com'].include?(payload['iss'])
    email_ok = payload['email_verified'].to_s == 'true'
    raise 'Неверный audience (aud)' unless aud_ok
    raise 'Неверный issuer' unless iss_ok
    raise 'Email не подтвержден Google' unless email_ok

    payload
  end

  def google_client_id
    ENV['GOOGLE_OAUTH_CLIENT_ID'] || 'REPLACE_ME'
  end
end
