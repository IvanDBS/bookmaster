class WorkingDayException < ApplicationRecord
  belongs_to :user

  validates :date, presence: true, uniqueness: { scope: :user_id }
  validates :is_working, inclusion: { in: [true, false] }

  after_destroy :recreate_slots_for_date
  after_save :recreate_slots_for_date

  private

  def recreate_slots_for_date
    user.ensure_slots_for_date(date)
  end
end
