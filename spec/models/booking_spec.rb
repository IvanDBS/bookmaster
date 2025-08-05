require 'rails_helper'

RSpec.describe Booking, type: :model do
  let(:master) { create(:user, role: 'master') }
  let(:service) { create(:service, user: master) }

  describe 'validations' do
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:client_name) }
    it { should validate_presence_of(:client_email) }
    it { should validate_inclusion_of(:status).in_array(%w[pending confirmed cancelled completed]) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:service) }
  end

  describe 'scopes' do
    let!(:pending_booking) { create(:booking, status: 'pending') }
    let!(:confirmed_booking) { create(:booking, status: 'confirmed') }
    let!(:cancelled_booking) { create(:booking, status: 'cancelled') }

    it 'returns pending bookings' do
      expect(Booking.pending).to include(pending_booking)
      expect(Booking.pending).not_to include(confirmed_booking)
    end

    it 'returns confirmed bookings' do
      expect(Booking.confirmed).to include(confirmed_booking)
      expect(Booking.confirmed).not_to include(pending_booking)
    end
  end

  describe 'callbacks' do
    let(:booking) { build(:booking, start_time: 1.hour.from_now) }

    it 'sets end_time based on service duration' do
      booking.save
      expect(booking.end_time).to eq(booking.start_time + booking.service.duration.minutes)
    end
  end

  describe 'validations' do
    it 'validates start_time is in future' do
      booking = build(:booking, start_time: 1.hour.ago)
      expect(booking).not_to be_valid
      expect(booking.errors[:start_time]).to include('должно быть в будущем')
    end

    # TODO: Fix this test - validation logic needs review
    # it 'validates end_time is after start_time' do
    #   booking = Booking.new(
    #     user: create(:user, role: 'master'),
    #     service: create(:service),
    #     start_time: 1.hour.from_now,
    #     end_time: 30.minutes.from_now,
    #     status: 'pending',
    #     client_name: 'Test Client',
    #     client_email: 'test@example.com'
    #   )
    #   booking.valid?
    #   expect(booking.errors[:end_time]).to include('должно быть после времени начала')
    # end
  end

  describe 'methods' do
    let(:booking) { create(:booking, start_time: Time.current + 1.hour) }

    it 'returns formatted start time' do
      expect(booking.formatted_start_time).to match(/\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}/)
    end

    it 'returns formatted end time' do
      expect(booking.formatted_end_time).to match(/\d{2}:\d{2}/)
    end

    it 'checks if can be confirmed' do
      expect(booking.can_be_confirmed?).to be true
    end

    it 'checks if can be cancelled' do
      expect(booking.can_be_cancelled?).to be true
    end
  end
end
