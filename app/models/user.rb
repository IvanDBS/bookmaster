class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Associations
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :working_schedules, dependent: :destroy
  has_many :time_slots, dependent: :destroy
  has_many :working_day_exceptions, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[master client] }
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :phone, presence: true, format: { with: /\A\+?[\d\s\-\(\)]+\z/ }

  # Scopes
  scope :masters, -> { where(role: 'master') }
  scope :clients, -> { where(role: 'client') }

  # Methods
  def master?
    role == 'master'
  end

  def client?
    role == 'client'
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.presence || email
  end

  # Методы для работы со слотами (только для мастеров)
  def generate_slots_for_date(date)
    return [] unless master?
    
    Rails.logger.info "User##{id}: Attempting to generate slots for date #{date} (wday: #{date.wday})"
    schedule = working_schedules.find_by(day_of_week: date.wday)
    if schedule
      Rails.logger.info "User##{id}: Found schedule for day #{date.wday}: is_working=#{schedule.is_working}, start_time=#{schedule.start_time&.strftime('%H:%M')}, end_time=#{schedule.end_time&.strftime('%H:%M')}"
    else
      Rails.logger.info "User##{id}: No schedule found for day #{date.wday}. Returning empty slots."
      return []
    end
    
    schedule.generate_slots_for_date(date)
  end

  def available_slots_for_date(date)
    time_slots.for_date(date).available.work_slots.order(:start_time)
  end

  def create_default_schedule!
    return unless master?
    return if working_schedules.exists?

    # Создаем стандартное расписание: Пн-Пт 9:00-18:00, обед 13:00-14:00
    (1..5).each do |day|
      working_schedules.create!(
        day_of_week: day,
        start_time: '09:00',
        end_time: '18:00',
        lunch_start: '13:00',
        lunch_end: '14:00',
        is_working: true,
        slot_duration_minutes: 60
      )
    end

    # Выходные дни
    [0, 6].each do |day|
      working_schedules.create!(
        day_of_week: day,
        is_working: false
      )
    end
  end

  def ensure_slots_for_date(date)
    return unless master?
    
    Rails.logger.info "User##{id}: ensure_slots_for_date called for date #{date} (wday: #{date.wday})"

    # Санитация: удаляем заведомо некорректные слоты на эту дату
    time_slots.for_date(date).where('end_time <= start_time').destroy_all

    # Проверяем, есть ли исключение для этой даты
    exception = working_day_exceptions.find_by(date: date)
    
    # Определяем, является ли этот день рабочим
    if exception
      # Исключение имеет приоритет над обычным расписанием
      is_working_day = exception.is_working
      Rails.logger.info "User##{id}: Found exception for #{date}: is_working=#{is_working_day}"
    else
      # Используем обычное расписание
      schedule = working_schedules.find_by(day_of_week: date.wday)
      is_working_day = schedule && schedule.is_working
      Rails.logger.info "User##{id}: Using schedule for #{date.wday} (is_working: #{is_working_day})"
    end
    
    # Генерируем слоты только если это рабочий день (по расписанию или исключению)
    if is_working_day
      slot_data = generate_slots_for_date(date)
      Rails.logger.info "User##{id}: Generated #{slot_data.length} slots for date #{date}"
      
      slot_data.each do |slot_attrs|
        begin
          # Ищем существующий слот по времени начала (точное совпадение часа и минуты)
          existing = time_slots.for_date(date)
                                 .where('EXTRACT(HOUR FROM start_time) = ? AND EXTRACT(MINUTE FROM start_time) = ?',
                                        slot_attrs[:start_time].hour, slot_attrs[:start_time].min)
                                 .first

          if existing
            # Не трогаем занятые и вручную заблокированные слоты
            next if existing.booking_id.present? || existing.slot_type == 'blocked'

            # Если тип отличается (например, мастер вручную поменял тип), уважаем ручное изменение и не перезаписываем тип
            attrs_to_update = {
              end_time: slot_attrs[:end_time],
              duration_minutes: slot_attrs[:duration_minutes]
            }
            if existing.slot_type == slot_attrs[:slot_type]
              attrs_to_update[:is_available] = slot_attrs[:is_available]
            end

            # Обновляем через валидации, чтобы не появлялись слоты с end_time < start_time
            existing.update!(attrs_to_update)
            Rails.logger.info "User##{id}: Updated existing slot #{existing.id} for #{date}"
          else
            # Создаем слот, если такого нет
            time_slots.create!(
              date: slot_attrs[:date],
              start_time: slot_attrs[:start_time],
              end_time: slot_attrs[:end_time],
              duration_minutes: slot_attrs[:duration_minutes],
              is_available: slot_attrs[:is_available],
              slot_type: slot_attrs[:slot_type]
            )
            Rails.logger.info "User##{id}: Created slot: #{slot_attrs[:start_time]} - #{slot_attrs[:end_time]} (type: #{slot_attrs[:slot_type]}, available: #{slot_attrs[:is_available]})"
          end
        rescue => e
          Rails.logger.error "User##{id}: Error ensuring slot for #{date}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end

      # ВАЖНО: после генерации слотов синхронизируем существующие брони с тайм-слотами,
      # чтобы занятые слоты не отображались как свободные
      reconcile_bookings_with_slots_for_date(date)
    else
      Rails.logger.info "User##{id}: Not generating new slots for #{date} as it is not a working day."
    end
  end

  # Сопоставляет бронирования с тайм-слотами на дату: проставляет booking_id и is_available=false
  def reconcile_bookings_with_slots_for_date(date)
    return unless master?

    day_bookings = bookings.where(start_time: date.all_day)
    Rails.logger.info "User##{id}: Reconciling #{day_bookings.count} bookings with time slots for #{date}"

    day_bookings.find_each do |booking|
      # Берем локальное время брони в зоне приложения,
      # чтобы корректно сопоставить с полем time в слоте
      local_start = booking.start_time.in_time_zone(Time.zone)

      # Находим слот по часу и минуте начала
      slot = time_slots.for_date(date)
                       .where(slot_type: 'work')
                       .where('EXTRACT(HOUR FROM start_time) = ? AND EXTRACT(MINUTE FROM start_time) = ?', local_start.hour, local_start.min)
                       .first
      if slot && slot.booking_id != booking.id
        slot.update_columns(booking_id: booking.id, is_available: false, updated_at: Time.current)
        Rails.logger.info "User##{id}: Linked slot #{slot.id} to booking #{booking.id}"
      end

      # Если бронь длиннее одного слота, пытаемся связать последующие слоты
      if slot && booking.service&.duration.to_i > slot.duration_minutes
        required_slots = (booking.service.duration.to_f / slot.duration_minutes).ceil
        (1...required_slots).each do |i|
          next_start = Time.zone.parse("2000-01-01 #{slot.start_time.strftime('%H:%M')}") + (i * slot.duration)
          follow_slot = time_slots.for_date(date)
                                   .where(slot_type: 'work')
                                   .where('EXTRACT(HOUR FROM start_time) = ? AND EXTRACT(MINUTE FROM start_time) = ?', next_start.hour, next_start.min)
                                   .first
          if follow_slot && follow_slot.booking_id != booking.id
            follow_slot.update_columns(booking_id: booking.id, is_available: false, updated_at: Time.current)
            Rails.logger.info "User##{id}: Linked follow-up slot #{follow_slot.id} to booking #{booking.id}"
          end
        end
      end
    end
  end
end
