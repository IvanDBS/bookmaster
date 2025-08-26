require 'rails_helper'

RSpec.describe 'Bookings API', type: :request do
  let!(:master) { create(:user, :confirmed, role: 'master', phone: '+0000000002', first_name: 'Max', last_name: 'Ava') }
  let!(:service) { create(:service, user: master, duration: 30) }
  let!(:client) do
    create(:user, :confirmed, role: 'client', phone: '+0000000003', first_name: 'Carl', last_name: 'Lee',
                              email: 'cli@example.com', password: 'password123')
  end

  def auth_headers(user)
    post '/api/v1/auth/login', params: { user: { email: user.email, password: 'password123' } }
    token = response.parsed_body['token']
    { 'Authorization' => "Bearer #{token}" }
  end

  it 'creates booking and returns 201' do
    # prepare time slot
    date = Date.current + 1.day
    master.create_default_schedule!
    master.ensure_slots_for_date(date)
    slot = master.time_slots.for_date(date).work_slots.available.first
    expect(slot).to be_present

    post '/api/v1/bookings',
         params: { master_id: master.id, time_slot_id: slot.id, booking: { service_id: service.id } }, headers: auth_headers(client)
    expect(response).to have_http_status(:created)
  end
end

RSpec.describe "Api::V1::Bookings", type: :request do
  let!(:master) { create(:user, role: 'master') }
  let!(:client) { create(:user, role: 'client') }
  let!(:service) { create(:service, user: master, duration: 60) }

  describe "POST /api/v1/bookings (role access)" do
    it "forbids master from creating bookings" do
      post '/api/v1/auth/login', params: { user: { email: master.email, password: 'password123' } }
      token = response.parsed_body['token']
      post "/api/v1/bookings",
           params: { master_id: master.id, time_slot_id: 1, booking: { service_id: service.id, client_name: 'Xavier', client_email: 'x@example.com' } }, headers: { 'Authorization' => "Bearer #{token}" }
      expect([401, 403]).to include(response.status)
    end
  end
end
