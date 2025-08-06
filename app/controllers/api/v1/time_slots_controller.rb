class Api::V1::TimeSlotsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :ensure_master!, only: [:index, :show]

  def index
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    
    # Генерируем слоты если их нет
    current_user.ensure_slots_for_date(date)
    
    # Получаем слоты на дату
    slots = current_user.time_slots.for_date(date).order(:start_time)
    
    render json: {
      date: date,
      slots: slots.map do |slot|
        {
          id: slot.id,
          start_time: slot.start_time.strftime('%H:%M'),
          end_time: slot.end_time.strftime('%H:%M'),
          duration_minutes: slot.duration_minutes,
          is_available: slot.is_available,
          slot_type: slot.slot_type,
          booked: slot.booked?,
          booking: slot.booking_id ? booking_details(slot.booking) : nil
        }
      end
    }
  end

  def show
    slot = current_user.time_slots.find(params[:id])
    
    render json: {
      id: slot.id,
      date: slot.date,
      start_time: slot.start_time.strftime('%H:%M'),
      end_time: slot.end_time.strftime('%H:%M'),
      duration_minutes: slot.duration_minutes,
      is_available: slot.is_available,
      slot_type: slot.slot_type,
      booked: slot.booked?,
      booking: slot.booking_id ? booking_details(slot.booking) : nil
    }
  end

  private

  def booking_details(booking)
    return nil unless booking
    
    {
      id: booking.id,
      client_name: booking.client_name,
      client_email: booking.client_email,
      client_phone: booking.client_phone,
      service_name: booking.service&.name,
      status: booking.status,
      start_time: booking.start_time,
      end_time: booking.end_time
    }
  end

  def ensure_master!
    render json: { error: 'Access denied. Masters only.' }, status: :forbidden unless current_user&.master?
  end
end