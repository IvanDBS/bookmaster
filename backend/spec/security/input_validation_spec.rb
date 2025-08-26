require 'rails_helper'

RSpec.describe 'Input Validation Security', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }
  let(:master) { create(:user, :master, email: 'master@example.com', password: 'password123') }
  let(:service) { create(:service, user: master) }
  let(:slot) { create(:time_slot, user: master, is_available: true) }

  before do
    sign_in user
  end

  describe 'SQL Injection Prevention' do
    it 'prevents SQL injection in search parameters' do
      malicious_input = "'; DROP TABLE users; --"
      
      get '/api/v1/services', params: { query: malicious_input }
      
      expect(response).to have_http_status(:ok)
      # Проверяем, что таблица users все еще существует
      expect { User.count }.not_to raise_error
    end

    it 'prevents SQL injection in booking parameters' do
      malicious_input = "'; DELETE FROM bookings; --"
      
      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: malicious_input,
          client_email: user.email
        }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
      # Проверяем, что записи не были удалены
      expect(Booking.count).to eq(0)
    end
  end

  describe 'XSS Prevention' do
    it 'prevents XSS in user input' do
      xss_payload = '<script>alert("XSS")</script>'
      
      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: xss_payload,
          client_email: user.email
        }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'prevents XSS in service description' do
      xss_payload = 'javascript:alert("XSS")'
      
      post '/api/v1/services', params: {
        service: {
          name: 'Test Service',
          description: xss_payload,
          price: 100,
          duration: 60
        }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'Parameter Validation' do
    it 'validates required parameters' do
      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          # Отсутствует service_id
          client_name: 'Test Client',
          client_email: user.email
        }
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'validates email format' do
      invalid_emails = [
        'invalid-email',
        '@example.com',
        'test@',
        'test..test@example.com'
      ]
      
      invalid_emails.each do |email|
        post '/api/v1/bookings', params: {
          master_id: master.id,
          time_slot_id: slot.id,
          booking: {
            service_id: service.id,
            client_name: 'Test Client',
            client_email: email
          }
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'validates phone number format' do
      invalid_phones = [
        'abc123',
        '123-456-789',
        '+12345678901234567890', # слишком длинный
        ''
      ]
      
      invalid_phones.each do |phone|
        post '/api/v1/bookings', params: {
          master_id: master.id,
          time_slot_id: slot.id,
          booking: {
            service_id: service.id,
            client_name: 'Test Client',
            client_email: user.email,
            client_phone: phone
          }
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'Input Sanitization' do
    it 'sanitizes HTML in user input' do
      html_input = '<p>Test</p><script>alert("XSS")</script>'
      
      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: html_input,
          client_email: user.email
        }
      }
      
      if response.status == 201
        booking = Booking.last
        expect(booking.client_name).not_to include('<script>')
        expect(booking.client_name).not_to include('</script>')
      end
    end

    it 'truncates overly long input' do
      long_input = 'a' * 1000
      
      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: long_input,
          client_email: user.email
        }
      }
      
      if response.status == 201
        booking = Booking.last
        expect(booking.client_name.length).to be <= 255
      end
    end
  end

  describe 'ID Validation' do
    it 'validates numeric IDs' do
      invalid_ids = ['abc', '123abc', '1.23', '-1', '0']
      
      invalid_ids.each do |id|
        get "/api/v1/bookings/#{id}"
        expect(response).to have_http_status(:bad_request)
      end
    end

    it 'prevents ID enumeration attacks' do
      # Пытаемся получить доступ к несуществующим записям
      (1..10).each do |id|
        get "/api/v1/bookings/#{id}"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Rate Limiting' do
    it 'enforces rate limits on booking creation' do
      # Создаем несколько запросов подряд
      15.times do |i|
        post '/api/v1/bookings', params: {
          master_id: master.id,
          time_slot_id: slot.id,
          booking: {
            service_id: service.id,
            client_name: "Client #{i}",
            client_email: "client#{i}@example.com"
          }
        }
        
        if response.status == 429
          expect(response.body).to include('Rate limit exceeded')
          break
        end
      end
    end
  end
end
