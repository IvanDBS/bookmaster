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
    
    schedule = working_schedules.find_by(day_of_week: date.wday)
    return [] unless schedule
    
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
    return if time_slots.for_date(date).exists?

    slot_data = generate_slots_for_date(date)
    slot_data.each do |slot_attrs|
      time_slots.create!(slot_attrs)
    end
  end
end
