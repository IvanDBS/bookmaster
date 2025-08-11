require 'rails_helper'

RSpec.describe WorkingDayException, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_inclusion_of(:is_working).in_array([true, false]) }

    context 'uniqueness' do
      let(:user) { create(:user, role: 'master') }
      let!(:existing_exception) { create(:working_day_exception, user: user, date: Date.current) }

      it 'validates uniqueness of date scoped to user' do
        new_exception = build(:working_day_exception, user: user, date: Date.current)
        expect(new_exception).not_to be_valid
        expect(new_exception.errors[:date]).to include('has already been taken')
      end

      it 'allows same date for different users' do
        other_user = create(:user, role: 'master', email: 'other@example.com')
        new_exception = build(:working_day_exception, user: other_user, date: Date.current)
        expect(new_exception).to be_valid
      end
    end
  end

  describe 'callbacks' do
    let(:user) { create(:user, role: 'master') }
    let(:exception_date) { Date.current + 1.day }

    before do
      user.create_default_schedule!
    end

    context 'after_save' do
      it 'calls recreate_slots_for_date' do
        expect_any_instance_of(User).to receive(:ensure_slots_for_date).with(exception_date)
        create(:working_day_exception, user: user, date: exception_date)
      end
    end

    context 'after_destroy' do
      it 'calls recreate_slots_for_date' do
        exception = create(:working_day_exception, user: user, date: exception_date)
        expect_any_instance_of(User).to receive(:ensure_slots_for_date).with(exception_date)
        exception.destroy
      end
    end
  end
end
