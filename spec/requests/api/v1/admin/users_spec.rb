require 'rails_helper'

RSpec.describe 'Admin::Users API', type: :request do
  let!(:admin) { create(:user, :confirmed, role: 'admin', email: 'admin@example.com', password: 'password123', phone: '+0000000000', first_name: 'Admin', last_name: 'User') }
  let!(:user)  { create(:user, :confirmed, role: 'client', email: 'user@example.com', password: 'password123', phone: '+0000000001', first_name: 'John', last_name: 'Doe') }

  def auth_headers(user)
    post '/api/v1/auth/login', params: { user: { email: user.email, password: 'password123' } }
    token = JSON.parse(response.body)['token']
    { 'Authorization' => "Bearer #{token}" }
  end

  it 'lists users with data/meta envelope' do
    get '/api/v1/admin/users', headers: auth_headers(admin)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body).to have_key('data')
    expect(body).to have_key('meta')
  end

  it 'updates user role' do
    put "/api/v1/admin/users/#{user.id}", params: { user: { role: 'master' } }, headers: auth_headers(admin)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['data']).to be_present
    expect(User.find(user.id).role).to eq('master')
  end
end


