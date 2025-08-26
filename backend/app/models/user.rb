class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Associations
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :working_schedules, dependent: :destroy
  has_many :time_slots, dependent: :destroy
  has_many :working_day_exceptions, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[master client admin] }

  # Roles enum (string-backed)
  enum :role, { client: 'client', master: 'master', admin: 'admin' }
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

  def admin?
    role == 'admin'
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    full_name.presence || email
  end

  # JWT payload method
  def jwt_payload
    {
      sub: id,
      email: email,
      role: role,
      exp: 24.hours.from_now.to_i
    }
  end

  # Deliver Devise emails asynchronously via ActiveJob/Sidekiq
  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end

  # Методы для работы со слотами (только для мастеров)
  def generate_slots_for_date(date, force_working: false)
    return [] unless master?

    schedule = working_schedules.find_by(day_of_week: date.wday)
    return [] unless schedule

    schedule.generate_slots_for_date(date, force_working: force_working)
  end

  def available_slots_for_date(date)
    time_slots.for_date(date).available.work_slots.order(:start_time)
  end

  def create_default_schedule!
    return unless master?
    return if working_schedules.exists?

    # Создаем стандартное расписание:
    # Рабочие дни: Пн(1)–Пт(5) 09:00–18:00, обед 13:00–14:00
    (1..5).each do |day|
      working_schedules.create!(
        day_of_week: day,
        start_time: '09:00',
        end_time: '18:00',
        lunch_start: '13:00',
        lunch_end: '14:00',
        is_working: true,
        slot_duration_minutes: 30
      )
    end

    # Суббота (6) — выходной
    working_schedules.create!(
      day_of_week: 6,
      is_working: false
    )

    # Воскресенье (0) — выходной
    working_schedules.create!(
      day_of_week: 0,
      is_working: false
    )
  end

  def ensure_slots_for_date(date)
    return unless master?

    # Санитация: удаляем заведомо некорректные слоты на эту дату
    time_slots.for_date(date).where('end_time <= start_time').destroy_all

    # Проверяем, есть ли исключение для этой даты
    exception = working_day_exceptions.find_by(date: date)

    # Определяем, является ли этот день рабочим
    if exception
      # Исключение имеет приоритет над обычным расписанием
      is_working_day = exception.is_working
    else
      # Используем обычное расписание
      schedule = working_schedules.find_by(day_of_week: date.wday)
      is_working_day = schedule&.is_working
    end

    # Генерируем слоты только если это рабочий день (по расписанию или исключению)
    return unless is_working_day

    slot_data = generate_slots_for_date(date, force_working: true)

    slot_data.each do |slot_attrs|
      # СТРОГАЯ ПРОВЕРКА: пропускаем некорректные интервалы (и любые попытки пересечь полночь)
      if slot_attrs[:end_time] <= slot_attrs[:start_time]
        Rails.logger.warn "User##{id}: Skipping invalid slot interval: #{slot_attrs[:start_time]} - #{slot_attrs[:end_time]}"
        next
      end

      # Ищем существующий слот по времени начала (точное совпадение часа и минуты)
      existing = time_slots.for_date(date)
                           .find_by(start_time: slot_attrs[:start_time])

      if existing
        # Не трогаем занятые и вручную заблокированные слоты
        next if existing.booking_id.present? || existing.slot_type == 'blocked'

        # Если тип отличается (например, мастер вручную поменял тип), уважаем ручное изменение и не перезаписываем тип
        attrs_to_update = {
          end_time: slot_attrs[:end_time],
          duration_minutes: slot_attrs[:duration_minutes]
        }
        attrs_to_update[:is_available] = slot_attrs[:is_available] if existing.slot_type == slot_attrs[:slot_type]

        # СТРОГАЯ ПРОВЕРКА: не обновляем если новый end_time некорректен
        if attrs_to_update[:end_time] && attrs_to_update[:end_time] <= (existing.start_time || slot_attrs[:start_time])
          Rails.logger.warn "User##{id}: Skipping update for slot #{existing.id} due to invalid end_time"
          next
        end

        # Обновляем через валидации, но избегаем ситуаций с end_time <= start_time
        begin
          existing.update!(attrs_to_update)
        rescue ActiveRecord::RecordInvalid
          next
        end
      else
        # Создаем слот, если такого нет
        # Дополнительная проверка: если имеется любой пересекающийся слот, пропускаем создание
        overlap_exists = time_slots.for_date(date)
                                   .exists?(['start_time < ? AND end_time > ?', slot_attrs[:end_time],
                                             slot_attrs[:start_time]])
        if overlap_exists
          Rails.logger.warn "User##{id}: Skipping creation due to overlap at #{slot_attrs[:start_time]}"
          next
        end
        begin
          time_slots.create!(
            date: slot_attrs[:date],
            start_time: slot_attrs[:start_time],
            end_time: slot_attrs[:end_time],
            duration_minutes: slot_attrs[:duration_minutes],
            is_available: slot_attrs[:is_available],
            slot_type: slot_attrs[:slot_type]
          )
        rescue ActiveRecord::RecordInvalid
          next
        end
      end
    rescue StandardError
      # Silent error handling for production
    end

    # ВАЖНО: после генерации слотов синхронизируем существующие брони с тайм-слотами,
    # чтобы занятые слоты не отображались как свободные
    reconcile_bookings_with_slots_for_date(date)
  end

  # Сопоставляет бронирования с тайм-слотами на дату: проставляет booking_id и is_available=false
  def reconcile_bookings_with_slots_for_date(date)
    return unless master?

    # Сначала освобождаем все слоты на эту дату, кроме вручную заблокированных
    time_slots.for_date(date)
              .update_all(
                booking_id: nil,
                is_available: Arel.sql("CASE WHEN slot_type IN ('blocked','lunch') THEN false ELSE true END"),
                updated_at: Time.current
              )

    # Берем только активные записи (не отмененные и не удаленные)
    active_bookings = bookings.where(start_time: date.all_day)
                              .where.not(status: 'cancelled')
                              .where.not(status: 'deleted')

    active_bookings.find_each do |booking|
      # Берем локальное время брони в зоне приложения,
      # чтобы корректно сопоставить с полем time в слоте
      local_start = booking.start_time.in_time_zone(Time.zone)

      # Находим слот по часу и минуте начала используя Ruby фильтрацию
      slot = time_slots.for_date(date)
                       .where(slot_type: 'work')
                       .find { |s| s.start_time.hour == local_start.hour && s.start_time.min == local_start.min }

      slot&.update_columns(booking_id: booking.id, is_available: false, updated_at: Time.current)

      # Если бронь длиннее одного слота, пытаемся связать последующие слоты
      if slot && booking.service&.duration.to_i > slot.duration_minutes
        required_slots = (booking.service.duration.to_f / slot.duration_minutes).ceil
        (1...required_slots).each do |i|
          next_start = Time.zone.parse("2000-01-01 #{slot.start_time.strftime('%H:%M')}") + (i * slot.duration_minutes).minutes
          follow_slot = time_slots.for_date(date)
                                  .where(slot_type: 'work')
                                  .find { |s| s.start_time.hour == next_start.hour && s.start_time.min == next_start.min }
          follow_slot&.update_columns(booking_id: booking.id, is_available: false, updated_at: Time.current)
        end
      end
    end
  end

  # GDPR compliance methods
  def soft_delete!
    update!(
      deleted_at: Time.current,
      email: "deleted_#{id}@deleted.com",
      first_name: "Deleted",
      last_name: "User",
      phone: "+0000000000"
    )
  end

  def permanently_delete!
    # Remove all personal data
    update!(
      email: "deleted_#{id}@deleted.com",
      first_name: "Deleted",
      last_name: "User",
      phone: "+0000000000",
      bio: nil,
      address: nil
    )
  end

  def really_destroy_all!
    # Окончательное удаление всех данных пользователя
    transaction do
      # Удаляем все связанные записи
      bookings.destroy_all
      services.destroy_all
      time_slots.destroy_all
      working_schedules.destroy_all
      working_day_exceptions.destroy_all

      # Окончательно удаляем пользователя
      super
    end
  end

  # GDPR методы
  def give_gdpr_consent!(version = '1.0')
    update!(
      gdpr_consent_at: Time.current,
      gdpr_consent_version: version
    )
  end

  def revoke_gdpr_consent!
    update!(
      gdpr_consent_at: nil,
      gdpr_consent_version: nil
    )
  end

  def give_marketing_consent!
    update!(
      marketing_consent: true,
      marketing_consent_at: Time.current
    )
  end

  def revoke_marketing_consent!
    update!(
      marketing_consent: false,
      marketing_consent_at: nil
    )
  end

  def request_data_export!
    update!(data_export_requested_at: Time.current)
  end

  def request_data_deletion!
    update!(data_deletion_requested_at: Time.current)
  end

  def has_gdpr_consent?
    gdpr_consent_at.present?
  end

  def has_marketing_consent?
    marketing_consent?
  end

  def can_be_deleted?
    # Проверяем, что прошло достаточно времени с момента запроса на удаление
    data_deletion_requested_at.present? && data_deletion_requested_at < 30.days.ago
  end

  def export_personal_data
    {
      id: id,
      email: email,
      first_name: first_name,
      last_name: last_name,
      phone: phone,
      bio: bio,
      address: address,
      role: role,
      created_at: created_at,
      updated_at: updated_at,
      gdpr_consent_at: gdpr_consent_at,
      gdpr_consent_version: gdpr_consent_version,
      marketing_consent: marketing_consent,
      marketing_consent_at: marketing_consent_at,
      data_export_requested_at: data_export_requested_at,
      data_deletion_requested_at: data_deletion_requested_at,
      bookings: bookings.map do |booking|
        {
          id: booking.id,
          service_name: booking.service&.name,
          start_time: booking.start_time,
          end_time: booking.end_time,
          status: booking.status,
          client_name: booking.client_name,
          client_email: booking.client_email,
          client_phone: booking.client_phone,
          created_at: booking.created_at,
          gdpr_consent_at: booking.gdpr_consent_at,
          data_retention_until: booking.data_retention_until
        }
      end,
      services: services.map do |service|
        {
          id: service.id,
          name: service.name,
          description: service.description,
          price: service.price,
          duration: service.duration,
          service_type: service.service_type,
          created_at: service.created_at
        }
      end,
      time_slots: time_slots.map do |slot|
        {
          id: slot.id,
          date: slot.date,
          start_time: slot.start_time,
          end_time: slot.end_time,
          slot_type: slot.slot_type,
          created_at: slot.created_at
        }
      end,
      working_schedules: working_schedules.map do |schedule|
        {
          id: schedule.id,
          day_of_week: schedule.day_of_week,
          start_time: schedule.start_time,
          end_time: schedule.end_time,
          is_working: schedule.is_working,
          created_at: schedule.created_at
        }
      end
    }
  end

  # Scopes for GDPR
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :for_deletion, -> { where(deleted_at: ...30.days.ago) }
  scope :with_gdpr_consent, -> { where.not(gdpr_consent_at: nil) }
  scope :without_gdpr_consent, -> { where(gdpr_consent_at: nil) }
  scope :marketing_consent, -> { where(marketing_consent: true) }
end
