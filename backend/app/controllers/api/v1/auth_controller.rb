class Api::V1::AuthController < ApplicationController
  before_action :authenticate_user_from_jwt!, only: [:profile, :logout]
  
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
      render_error(code: 'validation_error', message: user.errors.full_messages.join(', '), 
                   status: :unprocessable_entity)
    end
  end
  
  def login
    # Поддерживаем оба формата параметров
    email = params[:email] || params.dig(:user, :email)
    password = params[:password] || params.dig(:user, :password)
    
    user = User.find_by(email: email)
    
    if user&.valid_password?(password)
      unless user.confirmed?
        return render_error(code: 'unconfirmed', 
                            message: 'Email не подтвержден. Проверьте почту или запросите повторное письмо.', status: :unauthorized)
      end
      
      # Генерируем JWT токен
      payload = {
        user_id: user.id,
        email: user.email,
        role: user.role,
        exp: 1.hour.from_now.to_i
      }
      
      token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
      
      # Устанавливаем httpOnly cookie для безопасности
      response.set_cookie(
        'jwt_token',
        value: token,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :strict,
        path: '/',
        expires: 1.hour.from_now
      )
      
      render json: {
        user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
        message: 'Успешный вход'
      }
    else
      render_error(code: 'invalid_credentials', message: 'Неверный email или пароль', status: :unauthorized)
    end
  end

  def confirm
    token = params[:confirmation_token]
    if token.blank?
      return render_error(code: 'bad_request', message: 'Отсутствует confirmation_token', 
                          status: :bad_request)
    end

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
    return render json: { message: 'Если пользователь существует, письмо будет отправлено' } if user.nil?

    return render json: { message: 'Email уже подтвержден' } if user.confirmed?

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
          return render_error(code: 'validation_error', message: user.errors.full_messages.join(', '), 
                              status: :unprocessable_entity)
        end
      end

      # Аутентифицируем пользователя и генерируем JWT токен
      begin
        # Сначала генерируем токен
        require 'warden/jwt_auth'
        encoder = Warden::JWTAuth::UserEncoder.new
        token, _payload = encoder.call(user, :user, nil)
        
        # Затем устанавливаем пользователя в сессию (без сохранения в БД)
        sign_in user, store: false
      rescue StandardError => e
        Rails.logger.error("JWT encode failed: #{e.message}")
        return render_error(code: 'jwt_error', message: 'Ошибка генерации токена', status: :internal_server_error)
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

  # FedCM endpoint for Google OAuth
  def google_fedcm
    # FedCM requires specific headers
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    response.headers['Cross-Origin-Resource-Policy'] = 'cross-origin'
    
    # Set CORS headers for FedCM
    response.headers['Access-Control-Allow-Origin'] = request.headers['Origin'] || '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With, Sec-Fetch-Dest, Sec-Fetch-Mode, Sec-Fetch-Site'
    response.headers['Access-Control-Expose-Headers'] = 'Cross-Origin-Embedder-Policy, Cross-Origin-Opener-Policy, Cross-Origin-Resource-Policy'
    
    render json: {
      accounts: [
        {
          id: 'google',
          name: 'Google',
          given_name: 'Google',
          email: 'user@example.com',
          picture: 'https://accounts.google.com/favicon.ico'
        }
      ]
    }
  end
  
  # Google OAuth callback endpoint
  def google_callback
    # Handle Google OAuth callback
    code = params[:code]
    state = params[:state]
    
    if code.blank?
      return render_error(code: 'bad_request', message: 'Missing authorization code', status: :bad_request)
    end
    
    # Exchange code for tokens
    begin
      require 'net/http'
      require 'uri'
      require 'json'
      
      uri = URI('https://oauth2.googleapis.com/token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request.set_form_data({
        'client_id' => google_client_id,
        'client_secret' => ENV['GOOGLE_OAUTH_CLIENT_SECRET'],
        'code' => code,
        'grant_type' => 'authorization_code',
        'redirect_uri' => 'http://localhost:3000/api/v1/auth/google_callback'
      })
      
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        tokens = JSON.parse(response.body)
        id_token = tokens['id_token']
        
        # Verify and process the ID token
        payload = verify_google_id_token(id_token)
        email = payload['email']
        first_name = payload['given_name']
        last_name = payload['family_name']
        
        user = User.find_by(email: email)
        if user.nil?
          user = User.new(
            email: email,
            password: SecureRandom.hex(16),
            first_name: first_name.presence || 'Google',
            last_name: last_name.presence || 'User',
            role: 'client',
            phone: '+0000000000'
          )
          user.save!
        end
        
        # Generate JWT token
        require 'warden/jwt_auth'
        encoder = Warden::JWTAuth::UserEncoder.new
        token, _payload = encoder.call(user, :user, nil)
        sign_in user, store: false
        
        render json: {
          user: user.as_json(only: [:id, :email, :first_name, :last_name, :role]),
          token: token,
          message: 'Успешный вход через Google'
        }
      else
        render_error(code: 'oauth_error', message: 'Failed to exchange code for tokens', status: :bad_request)
      end
    rescue StandardError => e
      render_error(code: 'oauth_error', message: e.message, status: :bad_request)
    end
  end
  
  def profile
    render json: {
      user: current_user.as_json(only: [:id, :email, :first_name, :last_name, :role, :phone, :bio, :address])
    }
  end
  
  def logout
    sign_out current_user
    
    # Очищаем httpOnly cookie
    response.delete_cookie('jwt_token')
    
    render json: { message: 'Успешный выход' }
  end

  # GDPR compliance endpoints
  def export_data
    data = current_user.export_personal_data
    render json: { data: data }
  end

  def delete_account
    current_user.soft_delete!
    sign_out current_user
    render json: { message: 'Аккаунт удален. Данные будут полностью удалены через 30 дней.' }
  end

  def restore_account
    if current_user.deleted_at.present?
      current_user.update!(deleted_at: nil)
      render json: { message: 'Аккаунт восстановлен' }
    else
      render_error(code: 'bad_request', message: 'Аккаунт не был удален', status: :bad_request)
    end
  end
  
  private
  
  def user_params
    params.expect(user: [:email, :password, :password_confirmation, 
                         :first_name, :last_name, :phone, :role, :bio, :address])
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
