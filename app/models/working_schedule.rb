class WorkingSchedule < ApplicationRecord
  belongs_to :user

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :user_id, uniqueness: { scope: :day_of_week }
  validates :slot_duration_minutes, presence: true, numericality: { greater_than: 0 }, if: :is_working

  validate :working_hours_logic
  validate :lunch_within_working_hours

  scope :working_days, -> { where(is_working: true) }

  # Дни недели
  DAY_NAMES = {
    0 => 'Воскресенье',
    1 => 'Понедельник', 
    2 => 'Вторник',
    3 => 'Среда',
    4 => 'Четверг',
    5 => 'Пятница',
    6 => 'Суббота'
  }.freeze

  def day_name
    DAY_NAMES[day_of_week]
  end

  def working_duration_minutes
    return 0 unless is_working && start_time && end_time

    total_minutes = time_diff_in_minutes(end_time, start_time)
    lunch_minutes = lunch_duration_minutes
    
    [total_minutes - lunch_minutes, 0].max
  end

  def lunch_duration_minutes
    return 0 unless lunch_start && lunch_end
    
    time_diff_in_minutes(lunch_end, lunch_start)
  end

  def total_slots_count
    working_duration_minutes / slot_duration_minutes
  end

  # Генерация слотов для конкретной даты
  def generate_slots_for_date(date)
    return [] unless is_working && start_time && end_time
    return [] unless date.wday == day_of_week

    slots = []
    current_time = start_time
    
    while current_time < end_time
      slot_end = add_minutes_to_time(current_time, slot_duration_minutes)
      break if slot_end > end_time

      # Проверяем, не попадает ли слот на обеденное время
      if lunch_start && lunch_end
        if overlaps_with_lunch?(current_time, slot_end)
          current_time = add_minutes_to_time(current_time, slot_duration_minutes)
          next
        end
      end

      slots << {
        user: user,
        date: date,
        start_time: current_time,
        end_time: slot_end,
        duration_minutes: slot_duration_minutes,
        is_available: true,
        slot_type: 'work'
      }

      current_time = add_minutes_to_time(current_time, slot_duration_minutes)
    end

    # Добавляем обеденный слот если есть
    if lunch_start && lunch_end
      slots << {
        user: user,
        date: date,
        start_time: lunch_start,
        end_time: lunch_end,
        duration_minutes: lunch_duration_minutes,
        is_available: false,
        slot_type: 'lunch'
      }
    end

    slots
  end

  private

  def working_hours_logic
    return unless is_working

    if start_time.blank? || end_time.blank?
      errors.add(:start_time, 'обязательно для рабочих дней')
      errors.add(:end_time, 'обязательно для рабочих дней')
      return
    end

    if end_time <= start_time
      errors.add(:end_time, 'должно быть позже времени начала работы')
    end
  end

  def lunch_within_working_hours
    return unless is_working && start_time && end_time && lunch_start && lunch_end

    if lunch_start < start_time || lunch_end > end_time
      errors.add(:lunch_start, 'обед должен быть в рамках рабочего времени')
    end

    if lunch_end <= lunch_start
      errors.add(:lunch_end, 'должно быть позже времени начала обеда')
    end
  end

  def overlaps_with_lunch?(slot_start, slot_end)
    return false unless lunch_start && lunch_end
    
    !(slot_end <= lunch_start || slot_start >= lunch_end)
  end

  def time_diff_in_minutes(end_time, start_time)
    ((end_time.hour * 60 + end_time.min) - (start_time.hour * 60 + start_time.min)).abs
  end

  def add_minutes_to_time(time, minutes)
    total_minutes = time.hour * 60 + time.min + minutes
    hours = total_minutes / 60
    mins = total_minutes % 60
    Time.parse("#{hours}:#{mins}")
  end
end