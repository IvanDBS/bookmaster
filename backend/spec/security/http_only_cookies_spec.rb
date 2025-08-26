require 'rails_helper'

RSpec.describe 'HTTP Only Cookies Security', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'JWT token storage in httpOnly cookies' do
    it 'sets httpOnly cookie on login' do
      post '/api/v1/auth/login', params: {
        user: { email: user.email, password: 'password123' }
      }

      expect(response).to have_http_status(:ok)

      # Проверяем, что cookie установлен
      expect(response.headers['Set-Cookie']).to be_present
      expect(response.headers['Set-Cookie']).to include('jwt_token')
      expect(response.headers['Set-Cookie']).to include('HttpOnly')

      # Проверяем, что токен не возвращается в JSON
      json_response = JSON.parse(response.body)
      expect(json_response).not_to have_key('token')
    end

    it 'clears httpOnly cookie on logout' do
      # Сначала логинимся
      post '/api/v1/auth/login', params: {
        user: { email: user.email, password: 'password123' }
      }

      # Получаем cookie из ответа
      cookie = response.headers['Set-Cookie']

      # Делаем logout
      delete '/api/v1/auth/logout', headers: { 'Cookie' => cookie }

      expect(response).to have_http_status(:ok)

      # Проверяем, что cookie очищен
      expect(response.headers['Set-Cookie']).to include('jwt_token=;')
    end

    it 'requires authentication for protected endpoints' do
      # Попытка доступа без cookie
      get '/api/v1/bookings'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows access with valid httpOnly cookie' do
      # Логинимся
      post '/api/v1/auth/login', params: {
        user: { email: user.email, password: 'password123' }
      }

      cookie = response.headers['Set-Cookie']

      # Доступ к защищенному эндпоинту с cookie
      get '/api/v1/bookings', headers: { 'Cookie' => cookie }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Cookie security attributes' do
    it 'sets secure cookie in production' do
      allow(Rails.env).to receive(:production?).and_return(true)

      post '/api/v1/auth/login', params: {
        user: { email: user.email, password: 'password123' }
      }

      expect(response.headers['Set-Cookie']).to include('Secure')
    end

    it 'sets SameSite attribute' do
      post '/api/v1/auth/login', params: {
        user: { email: user.email, password: 'password123' }
      }

      expect(response.headers['Set-Cookie']).to include('SameSite=Strict')
    end
  end

  describe 'XSS protection' do
    it 'prevents XSS attacks through localStorage' do
      # Симулируем XSS атаку через localStorage
      # В новой реализации токен не должен быть доступен через localStorage

      post '/api/v1/auth/login', params: {
        user: { email: user.email, password: 'password123' }
      }

      json_response = JSON.parse(response.body)

      # Токен не должен быть в JSON ответе
      expect(json_response).not_to have_key('token')

      # Токен должен быть только в httpOnly cookie
      expect(response.headers['Set-Cookie']).to include('HttpOnly')
    end
  end
end
