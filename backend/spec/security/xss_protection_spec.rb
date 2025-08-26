require 'rails_helper'

RSpec.describe 'XSS Protection', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }
  let(:master) { create(:user, :master, email: 'master@example.com', password: 'password123') }

  before do
    sign_in user
  end

  describe 'XSS protection in user data' do
    it 'prevents XSS in user names' do
      # Создаем пользователя с потенциально опасным именем
      create(:user,
             first_name: '<script>alert("XSS")</script>',
             last_name: '"><img src=x onerror=alert("XSS2")>',
             email: 'test@example.com')

      # Получаем профиль пользователя
      get '/api/v1/auth/profile'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      # Проверяем, что HTML теги экранированы
      expect(json_response['user']['first_name']).to include('&lt;script&gt;')
      expect(json_response['user']['first_name']).not_to include('<script>')
      expect(json_response['user']['last_name']).to include('&quot;&gt;')
      expect(json_response['user']['last_name']).not_to include('"><img')
    end

    it 'prevents XSS in service names' do
      # Создаем услугу с потенциально опасным названием
      malicious_service = create(:service,
                                 user: master,
                                 name: '<script>alert("XSS")</script>',
                                 description: '"><img src=x onerror=alert("XSS2")>')

      # Получаем список услуг
      get '/api/v1/services'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      # Проверяем, что HTML теги экранированы
      service = json_response['data'].find { |s| s['id'] == malicious_service.id }
      expect(service['name']).to include('&lt;script&gt;')
      expect(service['name']).not_to include('<script>')
      expect(service['description']).to include('&quot;&gt;')
      expect(service['description']).not_to include('"><img')
    end

    it 'prevents XSS in booking data' do
      # Создаем бронирование с потенциально опасными данными
      service = create(:service, user: master)
      create(:time_slot, user: master, date: Date.tomorrow, is_available: true)

      malicious_booking = create(:booking,
                                 user: master,
                                 service: service,
                                 client_name: '<script>alert("XSS")</script>',
                                 client_email: 'test@example.com',
                                 client_phone: '"><img src=x onerror=alert("XSS2")>')

      # Получаем список бронирований
      get '/api/v1/bookings'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      # Проверяем, что HTML теги экранированы
      booking = json_response['data'].find { |b| b['id'] == malicious_booking.id }
      expect(booking['client_name']).to include('&lt;script&gt;')
      expect(booking['client_name']).not_to include('<script>')
      expect(booking['client_phone']).to include('&quot;&gt;')
      expect(booking['client_phone']).not_to include('"><img')
    end
  end

  describe 'Input validation and sanitization' do
    it 'sanitizes user input during registration' do
      post '/api/v1/auth/register', params: {
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          first_name: '<script>alert("XSS")</script>',
          last_name: '"><img src=x onerror=alert("XSS2")>',
          role: 'client'
        }
      }

      expect(response).to have_http_status(:created)

      # Проверяем, что пользователь создан с санитизированными данными
      user = User.find_by(email: 'test@example.com')
      expect(user.first_name).not_to include('<script>')
      expect(user.last_name).not_to include('"><img')
    end

    it 'sanitizes service input during creation' do
      sign_in master

      post '/api/v1/services', params: {
        service: {
          name: '<script>alert("XSS")</script>',
          description: '"><img src=x onerror=alert("XSS2")>',
          price: 100,
          duration: 60,
          service_type: 'massage'
        }
      }

      expect(response).to have_http_status(:created)

      # Проверяем, что услуга создана с санитизированными данными
      service = Service.last
      expect(service.name).not_to include('<script>')
      expect(service.description).not_to include('"><img')
    end

    it 'sanitizes booking input during creation' do
      service = create(:service, user: master)
      slot = create(:time_slot, user: master, date: Date.tomorrow, is_available: true)

      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: '<script>alert("XSS")</script>',
          client_email: 'test@example.com',
          client_phone: '"><img src=x onerror=alert("XSS2")>'
        }
      }

      expect(response).to have_http_status(:created)

      # Проверяем, что бронирование создано с санитизированными данными
      booking = Booking.last
      expect(booking.client_name).not_to include('<script>')
      expect(booking.client_phone).not_to include('"><img')
    end
  end

  describe 'JSON response sanitization' do
    it 'escapes HTML in JSON responses' do
      # Создаем пользователя с опасными данными
      create(:user,
             first_name: '<script>alert("XSS")</script>',
             last_name: '"><img src=x onerror=alert("XSS2")>',
             email: 'test@example.com')

      # Получаем данные пользователя через API
      get '/api/v1/auth/profile'

      expect(response).to have_http_status(:ok)

      # Проверяем, что JSON содержит экранированные символы
      response_body = response.body
      expect(response_body).to include('&lt;script&gt;')
      expect(response_body).to include('&quot;&gt;')
      expect(response_body).not_to include('<script>')
      expect(response_body).not_to include('"><img')
    end
  end

  describe 'Frontend data sanitization' do
    it 'validates frontend sanitization functions' do
      # Тестируем функции санитизации
      sanitizer = Class.new do
        include ActionView::Helpers::SanitizeHelper
      end.new

      # Тест экранирования HTML
      malicious_input = '<script>alert("XSS")</script>'
      sanitized = sanitizer.sanitize(malicious_input)
      expect(sanitized).not_to include('<script>')
      expect(sanitized).to include('&lt;script&gt;')

      # Тест удаления HTML тегов
      html_input = '<p>Hello <b>World</b></p>'
      text_only = sanitizer.strip_tags(html_input)
      expect(text_only).to eq('Hello World')
      expect(text_only).not_to include('<p>')
      expect(text_only).not_to include('<b>')
    end
  end
end
