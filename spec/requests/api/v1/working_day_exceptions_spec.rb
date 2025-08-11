require 'rails_helper'

RSpec.describe "Api::V1::WorkingDayExceptions", type: :request do
  let(:master) { create(:user, role: 'master') }
  let(:client) { create(:user, role: 'client', email: 'client@example.com') }

  before do
    master.create_default_schedule!
    sign_in master
  end

  describe 'GET /api/v1/working_day_exceptions' do
    let!(:exception1) { create(:working_day_exception, user: master, date: Date.current, is_working: false) }
    let!(:exception2) { create(:working_day_exception, user: master, date: Date.current + 1.day, is_working: true) }
    let!(:other_user_exception) { create(:working_day_exception, user: client, date: Date.current + 2.days) }

    it 'returns user\'s working day exceptions' do
      get '/api/v1/working_day_exceptions'

      expect(response).to have_http_status(:success)
      response_data = response.parsed_body
      expect(response_data.length).to eq(2)
      expect(response_data.map { |e| e['id'] }).to contain_exactly(exception1.id, exception2.id)
    end

    it 'requires authentication' do
      sign_out master
      get '/api/v1/working_day_exceptions'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/working_day_exceptions' do
    let(:valid_params) do
      {
        working_day_exception: {
          date: Date.current + 3.days,
          is_working: true,
          reason: 'Special working day'
        }
      }
    end

    it 'creates a working day exception' do
      expect do
        post '/api/v1/working_day_exceptions', params: valid_params
      end.to change(WorkingDayException, :count).by(1)

      expect(response).to have_http_status(:created)
      response_data = response.parsed_body
      expect(response_data['date']).to eq((Date.current + 3.days).to_s)
      expect(response_data['is_working']).to be true
      expect(response_data['reason']).to eq('Special working day')
    end

    it 'requires authentication' do
      sign_out master
      post '/api/v1/working_day_exceptions', params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/working_day_exceptions/toggle' do
    let(:toggle_date) { Date.current + 5.days }

    context 'when no exception exists' do
      it 'creates new exception with opposite status' do
        # Assuming Monday (day 1) is working day by default
        monday_date = Date.current.beginning_of_week + 1.day # Monday

        expect do
          post '/api/v1/working_day_exceptions/toggle',
               params: { date: monday_date }
        end.to change(WorkingDayException, :count).by(1)

        expect(response).to have_http_status(:created)
        response_data = response.parsed_body
        expect(response_data['date']).to eq(monday_date.to_s)
        expect(response_data['is_working']).to be false # Opposite of working day
      end
    end

    context 'when exception exists' do
      let!(:existing_exception) { create(:working_day_exception, user: master, date: toggle_date, is_working: false) }

      it 'toggles the existing exception' do
        expect do
          post '/api/v1/working_day_exceptions/toggle',
               params: { date: toggle_date }
        end.not_to change(WorkingDayException, :count)

        expect(response).to have_http_status(:success)
        response_data = response.parsed_body
        expect(response_data['is_working']).to be true # Toggled from false

        existing_exception.reload
        expect(existing_exception.is_working).to be true
      end
    end

    it 'requires authentication' do
      sign_out master
      post '/api/v1/working_day_exceptions/toggle',
           params: { date: toggle_date }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PUT /api/v1/working_day_exceptions/:id' do
    let!(:exception) { create(:working_day_exception, user: master, date: Date.current + 7.days, is_working: false) }
    let(:update_params) do
      {
        working_day_exception: {
          is_working: true,
          reason: 'Updated reason'
        }
      }
    end

    it 'updates the working day exception' do
      put "/api/v1/working_day_exceptions/#{exception.id}",
          params: update_params

      expect(response).to have_http_status(:success)
      response_data = response.parsed_body
      expect(response_data['is_working']).to be true
      expect(response_data['reason']).to eq('Updated reason')

      exception.reload
      expect(exception.is_working).to be true
      expect(exception.reason).to eq('Updated reason')
    end

    it 'requires authentication' do
      sign_out master
      put "/api/v1/working_day_exceptions/#{exception.id}",
          params: update_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/working_day_exceptions/:id' do
    let!(:exception) { create(:working_day_exception, user: master, date: Date.current + 10.days) }

    it 'deletes the working day exception' do
      expect do
        delete "/api/v1/working_day_exceptions/#{exception.id}"
      end.to change(WorkingDayException, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'requires authentication' do
      sign_out master
      delete "/api/v1/working_day_exceptions/#{exception.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
