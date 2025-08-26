require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_presence_of(:role) }

    it {
      expect(subject).to define_enum_for(:role)
        .backed_by_column_of_type(:string)
        .with_values(client: 'client', master: 'master', admin: 'admin')
    }
  end

  describe 'associations' do
    it { is_expected.to have_many(:services).dependent(:destroy) }
    it { is_expected.to have_many(:bookings).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:master) { create(:user, role: 'master') }
    let!(:client) { create(:user, role: 'client') }

    it 'returns only masters' do
      expect(described_class.masters).to include(master)
      expect(described_class.masters).not_to include(client)
    end

    it 'returns only clients' do
      expect(described_class.clients).to include(client)
      expect(described_class.clients).not_to include(master)
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
