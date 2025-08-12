class TimeSlotPublicSerializer < ActiveModel::Serializer
  attributes :id,
             :date,
             :start_time,
             :end_time,
             :start_at,
             :end_at,
             :duration_minutes,
             :is_available,
             :slot_type,
             :booked

  def start_time
    object.start_time.strftime('%H:%M')
  end

  def end_time
    object.end_time.strftime('%H:%M')
  end

  def start_at
    Time.zone.parse("#{object.date} #{object.start_time.strftime('%H:%M')}").iso8601
  end

  def end_at
    Time.zone.parse("#{object.date} #{object.end_time.strftime('%H:%M')}").iso8601
  end

  def booked
    object.booked?
  end
end


