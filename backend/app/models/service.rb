class Service < ApplicationRecord
  belongs_to :user
  has_many :bookings, dependent: :destroy

  # Service types
  SERVICE_TYPES = %w[маникюр педикюр массаж].freeze

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :duration, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :description, length: { maximum: 500 }
  validates :service_type, presence: true, inclusion: { in: SERVICE_TYPES }

  # Scopes
  scope :active, -> { joins(:user).where(users: { role: 'master' }) }
  scope :by_category, ->(category) { where("LOWER(name) LIKE ?", "%#{category.downcase}%") }
  scope :by_service_type, ->(service_type) { where(service_type: service_type) }

  # Class methods
  def self.available_service_types
    SERVICE_TYPES
  end

  # Instance methods
  def formatted_price
    "#{price.to_i} MDL"
  end

  def formatted_duration
    "#{duration} мин"
  end

  def master_name
    user.display_name
  end

  def service_type_display
    service_type.capitalize
  end
end
