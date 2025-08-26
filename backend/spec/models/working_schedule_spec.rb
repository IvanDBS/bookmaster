require 'rails_helper'

RSpec.describe WorkingSchedule, type: :model do
  let(:user) { create(:user, role: 'master') }
  let(:working_schedule) { create(:working_schedule, user: user) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:day_of_week) }
    it { is_expected.to validate_inclusion_of(:day_of_week).in_range(0..6) }

    context 'when is_working is true' do
      let(:schedule) { build(:working_schedule, is_working: true, start_time: nil, end_time: nil) }

      it 'requires start_time and end_time' do
        expect(schedule).not_to be_valid
        expect(schedule.errors[:start_time]).to include('обязательно для рабочих дней')
        expect(schedule.errors[:end_time]).to include('обязательно для рабочих дней')
      end

      it 'requires slot_duration_minutes' do
        schedule = build(:working_schedule, is_working: true, slot_duration_minutes: nil)
        expect(schedule).not_to be_valid
        expect(schedule.errors[:slot_duration_minutes]).to include("can't be blank")
      end
    end

    context 'when is_working is false' do
      let(:schedule) do
        build(:working_schedule, is_working: false, start_time: nil, end_time: nil, slot_duration_minutes: nil)
      end

      it 'does not require start_time and end_time' do
        expect(schedule).to be_valid
      end

      it 'does not require slot_duration_minutes' do
        expect(schedule).to be_valid
      end
    end
  end

  describe '#total_slots_count' do
    context 'when slot_duration_minutes is nil' do
      let(:schedule) { build(:working_schedule, slot_duration_minutes: nil) }

      it 'returns 0' do
        expect(schedule.total_slots_count).to eq(0)
      end
    end

    context 'when slot_duration_minutes is 0' do
      let(:schedule) { build(:working_schedule, slot_duration_minutes: 0) }

      it 'returns 0' do
        expect(schedule.total_slots_count).to eq(0)
      end
    end

    context 'when slot_duration_minutes is valid' do
      let(:schedule) { build(:working_schedule, start_time: '09:00', end_time: '19:00', slot_duration_minutes: 60) }

      it 'calculates correct number of slots' do
        # 10 hours = 600 minutes, 600 / 60 = 10 slots, но минус обед = 9 рабочих слотов
        expect(schedule.total_slots_count).to eq(9)
      end
    end
  end

  describe '#generate_slots_for_date' do
    let(:schedule) do
      build(:working_schedule, is_working: true, start_time: '09:00', end_time: '19:00', slot_duration_minutes: 60)
    end
    let(:date) { Date.current.beginning_of_week(:monday) }

    context 'when slot_duration_minutes is nil' do
      let(:schedule) { build(:working_schedule, slot_duration_minutes: nil) }

      it 'returns empty array' do
        expect(schedule.generate_slots_for_date(date)).to eq([])
      end
    end

    context 'when slot_duration_minutes is 0' do
      let(:schedule) { build(:working_schedule, slot_duration_minutes: 0) }

      it 'returns empty array' do
        expect(schedule.generate_slots_for_date(date)).to eq([])
      end
    end

    context 'when schedule is valid' do
      it 'generates correct number of slots' do
        slots = schedule.generate_slots_for_date(date)
        expect(slots.length).to eq(10) # 9 work slots + 1 lunch slot
      end

      it 'generates work slots with correct attributes' do
        slots = schedule.generate_slots_for_date(date)
        work_slots = slots.select { |s| s[:slot_type] == 'work' }

        expect(work_slots.length).to eq(9)
        work_slots.each do |slot|
          expect(slot[:is_available]).to be true
          expect(slot[:duration_minutes]).to eq(60)
        end
      end

      it 'generates lunch slot with correct attributes' do
        slots = schedule.generate_slots_for_date(date)
        lunch_slots = slots.select { |s| s[:slot_type] == 'lunch' }

        expect(lunch_slots.length).to eq(1)
        lunch_slot = lunch_slots.first
        expect(lunch_slot[:is_available]).to be false
      end
    end
  end

  describe '#day_name' do
    it 'returns correct day name' do
      schedule = build(:working_schedule, day_of_week: 1)
      expect(schedule.day_name).to eq('Понедельник')
    end
  end

  describe '#working_duration_minutes' do
    context 'when schedule is not working' do
      let(:schedule) { build(:working_schedule, is_working: false) }

      it 'returns 0' do
        expect(schedule.working_duration_minutes).to eq(0)
      end
    end

    context 'when schedule is working' do
      let(:schedule) do
        build(:working_schedule, start_time: '09:00', end_time: '19:00', lunch_start: '13:00', lunch_end: '14:00')
      end

      it 'calculates correct duration excluding lunch' do
        # 10 hours - 1 hour lunch = 9 hours = 540 minutes
        expect(schedule.working_duration_minutes).to eq(540)
      end
    end
  end
end
