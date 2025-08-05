require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:phone) }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[master client]) }
  end

  describe 'associations' do
    it { should have_many(:services).dependent(:destroy) }
    it { should have_many(:bookings).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:master) { create(:user, role: 'master') }
    let!(:client) { create(:user, role: 'client') }

    it 'returns only masters' do
      expect(User.masters).to include(master)
      expect(User.masters).not_to include(client)
    end

    it 'returns only clients' do
      expect(User.clients).to include(client)
      expect(User.clients).not_to include(master)
    end
  end

  describe 'methods' do
    let(:user) { create(:user, first_name: 'Иван', last_name: 'Петров') }

    it 'returns full name' do
      expect(user.full_name).to eq('Иван Петров')
    end

    it 'returns display name' do
      expect(user.display_name).to eq('Иван Петров')
    end

    it 'checks if user is master' do
      user.update(role: 'master')
      expect(user.master?).to be true
    end

    it 'checks if user is client' do
      user.update(role: 'client')
      expect(user.client?).to be true
    end
  end
end
