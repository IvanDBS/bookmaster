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
    return 0 unless is_working

    s = minutes_from_attr(:start_time)
    e = minutes_from_attr(:end_time)
    return 0 unless s && e && e > s

    total_minutes = time_diff_in_minutes_index(e, s)
    lunch_minutes = lunch_duration_minutes
    [total_minutes - lunch_minutes, 0].max
  end

  def lunch_duration_minutes
    ls = minutes_from_attr(:lunch_start)
    le = minutes_from_attr(:lunch_end)
    return 0 unless ls && le && le > ls

    time_diff_in_minutes_index(le, ls)
  end

  def total_slots_count
    return 0 unless slot_duration_minutes&.positive?

    working_duration_minutes / slot_duration_minutes
  end

  # Генерация слотов для конкретной даты
  # force_working: игнорировать флаг is_working для разового включения рабочего дня (исключение)
  def generate_slots_for_date(date, force_working: false)
    return [] unless (is_working || force_working) && start_time && end_time
    return [] unless date.wday == day_of_week
    return [] unless slot_duration_minutes&.positive?

    # Проверяем корректность рабочего времени (разрешаем 00:00-23:59)
    return [] if start_time == end_time

    slot_minutes = slot_duration_minutes || 60
    start_m = minutes_from_attr(:start_time)
    end_m   = minutes_from_attr(:end_time)
    lunch_s_m = minutes_from_attr(:lunch_start)
    lunch_e_m = minutes_from_attr(:lunch_end)

    # С 2025‑08: интервалы НЕ могут пересекать полночь. Если end <= start — не генерируем слоты.
    return [] if end_m.nil? || start_m.nil? || end_m <= start_m

    raw_slots = []
    m = start_m
    while m + slot_minutes <= end_m
      raw_slots << [m, m + slot_minutes]
      m += slot_minutes
    end

    # Фильтруем обед (если задан)
    if lunch_s_m && lunch_e_m
      raw_slots.reject! do |(a, b)|
        lunch_overlaps_minutes?(a, b, lunch_s_m, lunch_e_m)
      end
    end

    # Формируем структуры без TZ, как строки HH:MM:SS
    slots = raw_slots.map do |(a, b)|
      {
        user: user,
        date: date,
        start_time: minutes_to_hhmmss(a),
        end_time: minutes_to_hhmmss(b),
        duration_minutes: slot_minutes,
        is_available: true,
        slot_type: 'work'
      }
    end

    # Добавляем обеденный слот если есть и корректный интервал
    if lunch_s_m && lunch_e_m && ((lunch_e_m - lunch_s_m) % 1440).positive?
      slots << {
        user: user,
        date: date,
        start_time: minutes_to_hhmmss(lunch_s_m),
        end_time: minutes_to_hhmmss(lunch_e_m),
        duration_minutes: time_diff_in_minutes_index(lunch_e_m, lunch_s_m),
        is_available: false,
        slot_type: 'lunch'
      }
    end

    slots
  end

  private

  def working_hours_logic
    return unless is_working

    if read_attribute_before_type_cast(:start_time).blank? || read_attribute_before_type_cast(:end_time).blank?
      errors.add(:start_time, 'обязательно для рабочих дней')
      errors.add(:end_time, 'обязательно для рабочих дней')
      return
    end

    s = minutes_from_attr(:start_time)
    e = minutes_from_attr(:end_time)
    return unless e.nil? || s.nil? || e <= s

    errors.add(:end_time, 'должно быть позже времени начала (интервалы не могут пересекать полночь)')
  end

  def lunch_within_working_hours
    return unless is_working

    s = minutes_from_attr(:start_time)
    e = minutes_from_attr(:end_time)
    return unless s && e && e > s

    ls = minutes_from_attr(:lunch_start)
    le = minutes_from_attr(:lunch_end)
    # Если обед не задан — ок.
    return unless ls && le

    # Корректность интервала обеда
    if le <= ls
      errors.add(:lunch_end, 'должно быть позже времени начала обеда')
      return
    end

    # При запрете перехода через полночь обед обязан быть внутри рабочего интервала
    return unless ls < s || le > e

    errors.add(:lunch_start, 'обед должен быть в рамках рабочего времени')
  end

  def overlaps_with_lunch?(slot_start, slot_end, lunch_start_t = lunch_start, lunch_end_t = lunch_end)
    return false unless lunch_start_t && lunch_end_t

    if lunch_end_t < lunch_start_t
      # обед пересекает полночь
      !(slot_end <= lunch_start_t && slot_start >= lunch_end_t)
    else
      !(slot_end <= lunch_start_t || slot_start >= lunch_end_t)
    end
  end

  def time_diff_in_minutes_index(end_m, start_m)
    d = end_m - start_m
    d += 1440 if d.negative?
    d
  end

  def add_minutes_to_time(time, minutes)
    # Используем правильную логику для добавления минут к времени
    total_minutes = (time.hour * 60) + time.min + minutes
    hours = total_minutes / 60
    mins = total_minutes % 60

    # Обрабатываем переход через полночь (часы > 23)
    hours %= 24 if hours >= 24

    # Создаем новое время с правильными часами и минутами
    # Используем Time.zone.parse для корректной работы с часовыми поясами
    Time.zone.parse("2000-01-01 #{hours.to_s.rjust(2, '0')}:#{mins.to_s.rjust(2, '0')}:00")
  end

  def normalize_time_to_utc(time)
    # time — тип Time без даты (2000-01-01 HH:MM:SS в локальной зоне). Преобразуем к UTC с той же HH:MM.
    hh = time.hour
    mm = time.min
    Time.utc(2000, 1, 1, hh, mm, 0)
  end

  def minutes_from_attr(attr_name)
    raw = read_attribute_before_type_cast(attr_name)
    if raw.present? && raw.to_s =~ /^\d{2}:\d{2}/
      hh, mm = raw.to_s[0, 5].split(':').map(&:to_i)
      return (hh * 60) + mm
    end
    t = self[attr_name]
    return (t.hour * 60) + t.min if t

    nil
  end

  def minutes_to_hhmmss(mins)
    mins %= 1440
    hh = (mins / 60).floor
    mm = mins % 60
    Time.zone.parse("2000-01-01 #{format('%02d:%02d:00', hh, mm)}")
  end

  def lunch_overlaps_minutes?(a_start, a_end, l_start, l_end)
    if l_end < l_start
      # обед через полночь: считаем два отрезка
      overlap1 = !(a_end <= l_start || a_start >= 1440)
      overlap2 = !(a_end <= 0 || a_start >= l_end)
      overlap1 || overlap2
    else
      !(a_end <= l_start || a_start >= l_end)
    end
  end
end
