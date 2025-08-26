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
             :booked,
             :booking_id,
             :booking

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

  delegate :booking_id, to: :object

  def booking
    return nil unless object.booking_id

    {
      id: object.booking.id,
      client_name: object.booking.client_name,
      client_email: object.booking.client_email,
      client_phone: object.booking.client_phone,
      service_name: object.booking.service&.name,
      status: object.booking.status,
      start_time: object.booking.start_time,
      end_time: object.booking.end_time
    }
  end
end
