class Service < ApplicationRecord
  belongs_to :user
  has_many :bookings, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :duration, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :description, length: { maximum: 500 }

  # Scopes
  scope :active, -> { joins(:user).where(users: { role: 'master' }) }
  scope :by_category, ->(category) { where("LOWER(name) LIKE ?", "%#{category.downcase}%") }

  # Methods
  def formatted_price
    "₽#{price.to_i}"
  end

  def formatted_duration
    "#{duration} мин"
  end

  def master_name
    user.display_name
  end
end
