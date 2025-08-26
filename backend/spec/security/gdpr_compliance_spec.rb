require 'rails_helper'

RSpec.describe 'GDPR Compliance', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }
  let(:master) { create(:user, :master, email: 'master@example.com', password: 'password123') }

  before do
    sign_in user
  end

  describe 'GDPR Consent Management' do
    it 'allows user to give GDPR consent' do
      post '/api/v1/gdpr/give_consent', params: { version: '1.0' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to include('Согласие на обработку персональных данных дано')

      user.reload
      expect(user.has_gdpr_consent?).to be true
      expect(user.gdpr_consent_version).to eq('1.0')
    end

    it 'allows user to revoke GDPR consent' do
      user.give_gdpr_consent!

      post '/api/v1/gdpr/revoke_consent'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to include('Согласие на обработку персональных данных отозвано')

      user.reload
      expect(user.has_gdpr_consent?).to be false
    end

    it 'allows user to give marketing consent' do
      post '/api/v1/gdpr/give_marketing_consent'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to include('Согласие на маркетинговые сообщения дано')

      user.reload
      expect(user.has_marketing_consent?).to be true
    end

    it 'allows user to revoke marketing consent' do
      user.give_marketing_consent!

      post '/api/v1/gdpr/revoke_marketing_consent'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to include('Согласие на маркетинговые сообщения отозвано')

      user.reload
      expect(user.has_marketing_consent?).to be false
    end
  end

  describe 'Data Export' do
    it 'allows user to request data export' do
      post '/api/v1/gdpr/export_data'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to include('Запрос на экспорт данных принят')

      user.reload
      expect(user.data_export_requested_at).to be_present
    end

    it 'includes all user data in export' do
      # Создаем тестовые данные
      service = create(:service, user: master)
      create(:booking, user: master, service: service, client_email: user.email)

      data = user.export_personal_data

      expect(data).to include(:id, :email, :first_name, :last_name)
      expect(data).to include(:gdpr_consent_at, :gdpr_consent_version)
      expect(data).to include(:marketing_consent, :marketing_consent_at)
      expect(data).to include(:data_export_requested_at, :data_deletion_requested_at)
      expect(data[:bookings]).to be_an(Array)
      expect(data[:services]).to be_an(Array)
      expect(data[:time_slots]).to be_an(Array)
      expect(data[:working_schedules]).to be_an(Array)
    end
  end

  describe 'Data Deletion' do
    it 'allows user to request data deletion' do
      post '/api/v1/gdpr/request_deletion'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to include('Запрос на удаление данных принят')

      user.reload
      expect(user.data_deletion_requested_at).to be_present
    end

    it 'allows user to cancel deletion request' do
      user.request_data_deletion!

      post '/api/v1/gdpr/cancel_deletion'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to include('Запрос на удаление данных отменен')

      user.reload
      expect(user.data_deletion_requested_at).to be_nil
    end

    it 'prevents deletion before 30 days' do
      user.request_data_deletion!

      expect(user.can_be_deleted?).to be false
    end

    it 'allows deletion after 30 days' do
      user.update!(data_deletion_requested_at: 31.days.ago)

      expect(user.can_be_deleted?).to be true
    end
  end

  describe 'Consent Status' do
    it 'returns current consent status' do
      user.give_gdpr_consent!
      user.give_marketing_consent!

      get '/api/v1/gdpr/consent_status'

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response['gdpr_consent']['given']).to be true
      expect(json_response['gdpr_consent']['given_at']).to be_present
      expect(json_response['gdpr_consent']['version']).to eq('1.0')

      expect(json_response['marketing_consent']['given']).to be true
      expect(json_response['marketing_consent']['given_at']).to be_present

      expect(json_response['data_requests']['export_requested_at']).to be_nil
      expect(json_response['data_requests']['deletion_requested_at']).to be_nil
      expect(json_response['data_requests']['can_be_deleted']).to be false
    end
  end

  describe 'Booking GDPR Compliance' do
    it 'sets GDPR consent when creating booking' do
      service = create(:service, user: master)
      slot = create(:time_slot, user: master, date: Date.tomorrow, is_available: true)

      post '/api/v1/bookings', params: {
        master_id: master.id,
        time_slot_id: slot.id,
        booking: {
          service_id: service.id,
          client_name: user.full_name,
          client_email: user.email,
          client_phone: user.phone
        }
      }

      expect(response).to have_http_status(:created)

      booking = Booking.last
      expect(booking.gdpr_consent_at).to be_present
      expect(booking.data_retention_until).to be_present
      expect(booking.data_retention_until).to be > 29.days.from_now
    end
  end

  describe 'GDPR Cleanup Job' do
    it 'processes deletion requests after 30 days' do
      user.update!(data_deletion_requested_at: 31.days.ago)

      expect do
        GdprCleanupJob.perform_now
      end.to change { user.reload.deleted_at }.from(nil)

      expect(user.deleted_at).to be_present
    end

    it 'cleans up old bookings' do
      booking = create(:booking, user: master, data_retention_until: 1.day.ago)

      expect do
        GdprCleanupJob.perform_now
      end.to change(Booking, :count).by(-1)

      expect(Booking.find_by(id: booking.id)).to be_nil
    end
  end
end
