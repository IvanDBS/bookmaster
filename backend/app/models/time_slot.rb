class TimeSlot < ApplicationRecord
  belongs_to :user
  belongs_to :booking, optional: true

  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :slot_type, inclusion: { in: %w[work lunch blocked] }

  validate :end_time_after_start_time
  validate :no_overlapping_slots_for_user

  scope :available, -> { where(is_available: true, booking_id: nil) }
  scope :booked, -> { where.not(booking_id: nil) }
  scope :for_date, ->(date) { where(date: date) }
  scope :for_user, ->(user) { where(user: user) }
  scope :work_slots, -> { where(slot_type: 'work') }

  def booked?
    !booking_id.nil?
  end

  def duration
    duration_minutes.minutes
  end

  def datetime_start
    Time.zone.parse("#{date} #{start_time}")
  end

  def datetime_end
    Time.zone.parse("#{date} #{end_time}")
  end

  def can_be_booked?
    is_available && !booked? && slot_type == 'work'
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time

    # Жесткий запрет на переход через полночь для слотов: end_time должно быть позже start_time в пределах одного дня
    errors.add(:end_time, 'должно быть позже времени начала') if end_time <= start_time
  end

  def no_overlapping_slots_for_user
    return unless user && date && start_time && end_time

    overlapping_slots = TimeSlot.where(user: user, date: date)
                                .where.not(id: id)
                                .where('start_time < ? AND end_time > ?', end_time, start_time)

    return unless overlapping_slots.exists?

    errors.add(:start_time, 'пересекается с существующим слотом')
  end

  # Создает слот, записывая поля start_time/end_time как сырые значения HH:MM:SS
  # чтобы исключить любые TZ-сдвиги адаптера БД для типа :time
  def self.create_with_raw_times!(attrs)
    raise ArgumentError, 'user or user_id required' unless attrs[:user] || attrs[:user_id]

    user_id = attrs[:user_id] || attrs[:user].id
    date = attrs[:date]
    start_hms = attrs[:start_time]
    end_hms = attrs[:end_time]
    duration = attrs[:duration_minutes] || 60
    is_available = attrs.key?(:is_available) ? !attrs[:is_available].nil? : true
    booking_id = attrs[:booking_id]
    slot_type = attrs[:slot_type] || 'work'
    now = Time.current

    conn = connection
    sql = <<-SQL.squish
      INSERT INTO time_slots (user_id, date, start_time, end_time, duration_minutes, is_available, booking_id, slot_type, created_at, updated_at)
      VALUES (
        #{conn.quote(user_id)},
        #{conn.quote(date)},
        #{conn.quote(start_hms)}::time,
        #{conn.quote(end_hms)}::time,
        #{conn.quote(duration)},
        #{is_available ? conn.quoted_true : conn.quoted_false},
        #{booking_id ? conn.quote(booking_id) : 'NULL'},
        #{conn.quote(slot_type)},
        #{conn.quote(now)},
        #{conn.quote(now)}
      ) RETURNING id
    SQL
    result = conn.exec_query(sql)
    find(result.rows.first.first)
  end

  # Убедимся, что вышеуказанный private не влияет на класс-методы
  class << self
    public :create_with_raw_times!
  end

  # Метод должен быть публичным для вызова из контроллера
end
