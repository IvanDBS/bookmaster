require 'rails_helper'

RSpec.describe 'Bookings API', type: :request do
  let!(:master) { create(:user, role: 'master', phone: '+0000000002', first_name: 'M', last_name: 'A') }
  let!(:service) { create(:service, user: master, duration: 60) }
  let!(:client) { create(:user, role: 'client', phone: '+0000000003', first_name: 'C', last_name: 'L', email: 'cli@example.com', password: 'password') }

  def auth_headers(user)
    post '/api/v1/auth/login', params: { user: { email: user.email, password: 'password' } }
    token = JSON.parse(response.body)['token']
    { 'Authorization' => "Bearer #{token}" }
  end

  it 'creates booking and returns 201' do
    # prepare time slot
    date = Date.current + 1.day
    master.ensure_slots_for_date(date)
    slot = master.time_slots.for_date(date).work_slots.available.first
    expect(slot).to be_present

    post '/api/v1/bookings', params: { master_id: master.id, time_slot_id: slot.id, booking: { service_id: service.id } }, headers: auth_headers(client)
    expect(response).to have_http_status(:created)
  end
end

RSpec.describe "Api::V1::Bookings", type: :request do
  let!(:master) { create(:user, role: 'master') }
  let!(:client) { create(:user, role: 'client') }
  let!(:service) { create(:service, user: master, duration: 60) }

  describe "POST /api/v1/bookings (role access)" do
    it "forbids master from creating bookings" do
      sign_in master
      post "/api/v1/bookings", params: { master_id: master.id, time_slot_id: 1, booking: { service_id: service.id, client_name: 'X', client_email: 'x@example.com' } }
      expect(response.status).to eq(403)
    end
  end
end
