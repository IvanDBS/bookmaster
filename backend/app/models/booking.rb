class Booking < ApplicationRecord
  has_many :time_slots, dependent: :nullify
  belongs_to :user
  belongs_to :service

  # Status enum (string-backed)
  enum :status, { pending: 'pending', confirmed: 'confirmed', cancelled: 'cancelled', completed: 'completed' }

  # Validations
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending confirmed cancelled completed] }
  validates :client_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :client_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :client_phone, format: { with: /\A\+?[\d\s\-\(\)]+\z/ }, allow_blank: true

  # Callbacks
  before_validation :set_end_time, if: :start_time_changed?
  before_create :set_gdpr_consent
  validate :start_time_in_future
  validate :end_time_after_start_time
  validate :no_time_conflicts

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :completed, -> { where(status: 'completed') }
  scope :upcoming, -> { where('start_time > ?', Time.current) }
  scope :past, -> { where(start_time: ...Time.current) }
  scope :by_date, ->(date) { where(start_time: date.all_day) }

  # Methods
  def pending?
    status == 'pending'
  end

  def confirmed?
    status == 'confirmed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def completed?
    status == 'completed'
  end

  def can_be_confirmed?
    pending? && start_time > Time.current
  end

  def can_be_cancelled?
    %w[pending confirmed].include?(status) && start_time > Time.current
  end

  def formatted_start_time
    start_time.strftime('%d.%m.%Y %H:%M')
  end

  def formatted_end_time
    end_time.strftime('%H:%M')
  end

  private

  def set_end_time
    return unless start_time
    duration_minutes = service&.duration.to_i
    duration_minutes = 60 if duration_minutes <= 0
    self.end_time = start_time + duration_minutes.minutes
  end

  def start_time_in_future
    return unless start_time
    if start_time <= Time.current
      errors.add(:start_time, 'должно быть в будущем')
    end
  end

  def end_time_after_start_time
    return unless start_time && end_time
    if end_time <= start_time
      errors.add(:end_time, 'должно быть после времени начала')
    end
  end

  def no_time_conflicts
    return unless start_time && end_time && user_id

    # Конфликт по стандартному правилу пересечения интервалов:
    # (start_a < end_b) AND (end_a > start_b)
    conflicting_bookings = Booking.where(user_id: user_id)
                                  .where.not(id: id)
                                  .where(status: %w[pending confirmed])
                                  .where('start_time < ? AND end_time > ?', end_time, start_time)

    if conflicting_bookings.exists?
      errors.add(:start_time, 'время уже занято другим бронированием')
    end
  end

  def set_gdpr_consent
    # Устанавливаем GDPR согласие при создании брони
    self.gdpr_consent_at = Time.current
    self.data_retention_until = 30.days.from_now
  end
end
