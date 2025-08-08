class Api::V1::TimeSlotsController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:public_index]
  before_action :ensure_master!, only: [:index, :show, :update]

  def index
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    
    Rails.logger.info "Loading time slots for date: #{date} for user: #{current_user.id}"
    
    # Генерируем слоты если их нет
    current_user.ensure_slots_for_date(date)
    
    # Получаем слоты на дату и гарантируем актуальность занятости по существующим броням
    current_user.reconcile_bookings_with_slots_for_date(date)
    slots = current_user.time_slots.for_date(date).order(:start_time)
    
    Rails.logger.info "Found #{slots.count} slots for date #{date}"
    
    render json: {
      date: date,
      slots: slots.map do |slot|
        # Дополнительная защита: вычисляем занятость по пересечению с бронированиями,
        # даже если по каким-то причинам booking_id у слота не проставлен
        slot_start_dt = Time.zone.parse("#{slot.date} #{slot.start_time.strftime('%H:%M')}")
        slot_end_dt   = Time.zone.parse("#{slot.date} #{slot.end_time.strftime('%H:%M')}")
        overlapping_booking = Booking.where(user_id: current_user.id, status: %w[pending confirmed])
                                      .where('(start_time < ?) AND (end_time > ?)', slot_end_dt, slot_start_dt)
                                      .first
        computed_booked = slot.booked? || overlapping_booking.present?
        computed_available = slot.is_available && overlapping_booking.nil?
        {
          id: slot.id,
          start_time: slot.start_time.strftime('%H:%M'),
          end_time: slot.end_time.strftime('%H:%M'),
          duration_minutes: slot.duration_minutes,
          is_available: computed_available,
          slot_type: slot.slot_type,
          booked: computed_booked,
          booking: (slot.booking_id ? booking_details(slot.booking) : (overlapping_booking ? booking_details(overlapping_booking) : nil))
        }
      end
    }
  end

  # Публичная выдача слотов по мастеру и дате для клиентского сценария (без авторизации)
  def public_index
    master = User.masters.find_by(id: params[:master_id])
    return render json: { error: 'Мастер не найден' }, status: :not_found unless master

    date = params[:date] ? Date.parse(params[:date]) : Date.current
    master.ensure_slots_for_date(date)
    # Дополнительно синхронизируем брони со слотами для защиты от несвязанностей
    master.reconcile_bookings_with_slots_for_date(date)

    slots = master.time_slots.for_date(date).order(:start_time)
    render json: {
      date: date,
      slots: slots.map { |slot|
        {
          id: slot.id,
          start_time: slot.start_time,
          end_time: slot.end_time,
          duration_minutes: slot.duration_minutes,
          is_available: slot.is_available,
          slot_type: slot.slot_type,
          booked: slot.booked?
        }
      }
    }
  end

  def show
    slot = current_user.time_slots.find(params[:id])
    
    render json: {
      id: slot.id,
      date: slot.date,
      start_time: slot.start_time,
      end_time: slot.end_time,
      duration_minutes: slot.duration_minutes,
      is_available: slot.is_available,
      slot_type: slot.slot_type,
      booked: slot.booked?,
      booking: slot.booking_id ? booking_details(slot.booking) : nil
    }
  end

  # PATCH /api/v1/time_slots/:id  { is_break: true|false }
  # Переключение перерыва на слоте: если включили перерыв — слот становится slot_type='blocked' и недоступен; выключили — возвращаем 'work' и доступность true
  def update
    slot = current_user.time_slots.find(params[:id])

    unless params.key?(:is_break)
      return render json: { error: 'Missing parameter is_break' }, status: :bad_request
    end

    is_break = ActiveModel::Type::Boolean.new.cast(params[:is_break])

    # Запрещаем ставить перерыв, если есть любая пересекающаяся бронь (даже если слот не связан)
    slot_start_dt = Time.zone.parse("#{slot.date} #{slot.start_time.strftime('%H:%M')}")
    slot_end_dt   = Time.zone.parse("#{slot.date} #{slot.end_time.strftime('%H:%M')}")
    overlapping_booking = Booking.where(user_id: current_user.id, status: %w[pending confirmed])
                                  .where('(start_time < ?) AND (end_time > ?)', slot_end_dt, slot_start_dt)
                                  .first

    if is_break && (slot.booking_id.present? || overlapping_booking.present?)
      return render json: { error: 'Нельзя поставить перерыв: на это время есть запись' }, status: :unprocessable_entity
    end

    if is_break
      slot.update!(slot_type: 'blocked', is_available: false)
    else
      slot.update!(slot_type: 'work', is_available: true)
    end

    render json: {
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