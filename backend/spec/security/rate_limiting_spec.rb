require 'rails_helper'

RSpec.describe 'Rate Limiting', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'API rate limiting' do
    it 'limits API requests per IP' do
      # Делаем 301 запрос (превышаем лимит 300 за 5 минут)
      301.times do
        get '/api/v1/services'
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'limits login attempts per IP' do
      # Делаем 6 попыток входа (превышаем лимит 5 за 20 секунд)
      6.times do
        post '/api/v1/auth/login', params: {
          user: { email: user.email, password: 'wrong_password' }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'limits registration attempts per IP' do
      # Делаем 4 попытки регистрации (превышаем лимит 3 за час)
      4.times do
        post '/api/v1/auth/register', params: {
          user: {
            email: "test#{rand(1000)}@example.com",
            password: 'password123',
            first_name: 'Test',
            last_name: 'User'
          }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it 'limits booking creation attempts per IP' do
      sign_in user
      master = create(:user, :master)
      service = create(:service, user: master)
      slot = create(:time_slot, user: master, is_available: true)

      # Делаем 11 попыток создания бронирования (превышаем лимит 10 за минуту)
      11.times do
        post '/api/v1/bookings', params: {
          master_id: master.id,
          time_slot_id: slot.id,
          booking: {
            service_id: service.id,
            client_name: 'Test Client',
            client_email: user.email
          }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'IP blocking' do
    it 'blocks IP with too many 401 errors' do
      # Делаем 6 попыток доступа без авторизации
      6.times do
        get '/api/v1/bookings'
      end

      # Следующий запрос должен быть заблокирован
      get '/api/v1/services'
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
