require 'rails_helper'

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
