require 'rails_helper'

RSpec.describe Service, type: :model do
  let(:master) { create(:user, role: 'master') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_presence_of(:duration) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:duration).is_greater_than(0).only_integer }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:bookings).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:master_service) { create(:service, user: master) }
    let!(:client) { create(:user, role: 'client') }
    let!(:client_service) { create(:service, user: client) }

    it 'returns only active services from masters' do
      expect(described_class.active).to include(master_service)
      expect(described_class.active).not_to include(client_service)
    end
  end

  describe 'methods' do
    let(:service) { create(:service, user: master, price: 1500, duration: 60) }

    it 'returns formatted price' do
      expect(service.formatted_price).to eq('1500 MDL')
    end

    it 'returns formatted duration' do
      expect(service.formatted_duration).to eq('60 мин')
    end

    it 'returns master name' do
      expect(service.master_name).to eq(master.display_name)
    end
  end
end
