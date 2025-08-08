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
    
    errors.add(:end_time, 'должно быть позже времени начала') if end_time <= start_time
  end

  def no_overlapping_slots_for_user
    return unless user && date && start_time && end_time

    overlapping_slots = TimeSlot.where(user: user, date: date)
                               .where.not(id: id) # исключаем себя при обновлении
                               .where(
                                 '(start_time < ? AND end_time > ?) OR ' +
                                 '(start_time < ? AND end_time > ?) OR ' +
                                 '(start_time >= ? AND end_time <= ?)',
                                 start_time, start_time,
                                 end_time, end_time,
                                 start_time, end_time
                               )

    if overlapping_slots.exists?
      errors.add(:start_time, 'пересекается с существующим слотом')
    end
  end
end