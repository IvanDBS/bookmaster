module Api
  module V1
    class TimeSlotsController < Api::V1::BaseController
      before_action :ensure_master!, only: [:index, :show, :update, :add_slot]

      def index
        date = params[:date] ? Date.parse(params[:date]) : Date.current

        # Генерируем слоты если их нет
        current_user.ensure_slots_for_date(date)
        # ensure_slots_for_date уже вызывает reconcile_bookings_with_slots_for_date,
        # поэтому дополнительный вызов здесь не нужен, чтобы избежать лишней нагрузки
        slots = current_user.time_slots.for_date(date).includes(booking: :service).order(:start_time)

        render json: {
          slots: ActiveModelSerializers::SerializableResource.new(
            slots,
            each_serializer: TimeSlotSerializer
          )
        }
      end

      # Публичная выдача слотов по мастеру и дате для клиентского сценария (без авторизации)
      def public_index
        master = User.masters.find_by(id: params[:master_id])
        return render_error(code: 'not_found', message: 'Мастер не найден', status: :not_found) unless master

        date = params[:date] ? Date.parse(params[:date]) : Date.current
        master.ensure_slots_for_date(date)
        # ensure_slots_for_date уже синхронизирует слоты с бронированиями

        slots = master.time_slots.for_date(date).includes(booking: :service).order(:start_time)
        render json: slots, each_serializer: TimeSlotPublicSerializer
      end

      def show
        slot = current_user.time_slots.find(params[:id])

        render json: slot, serializer: TimeSlotSerializer
      end

      # PATCH /api/v1/time_slots/:id  { is_break: true|false }
      # Переключение перерыва на слоте: если включили перерыв — слот становится slot_type='blocked' и недоступен; выключили — возвращаем 'work' и доступность true
      def update
        slot = current_user.time_slots.find(params[:id])

        unless params.key?(:is_break)
          return render_error(code: 'bad_request', message: 'Missing parameter is_break',
                              status: :bad_request)
        end

        is_break = ActiveModel::Type::Boolean.new.cast(params[:is_break])

        # Запрещаем ставить перерыв, если есть любая пересекающаяся бронь (даже если слот не связан)
        slot_start_dt = Time.zone.parse("#{slot.date} #{slot.start_time.strftime('%H:%M')}")
        slot_end_dt   = Time.zone.parse("#{slot.date} #{slot.end_time.strftime('%H:%M')}")
        overlapping_booking = Booking.where(user_id: current_user.id, status: %w[pending confirmed])
                                     .where('(start_time < ?) AND (end_time > ?)', slot_end_dt, slot_start_dt)
                                     .first

        if is_break && (slot.booking_id.present? || overlapping_booking.present?)
          return render_error(code: 'validation_error', message: 'Нельзя поставить перерыв: на это время есть запись',
                              status: :unprocessable_entity)
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

      # POST /api/v1/time_slots/add_slot
      # Добавляет новый слот после последнего рабочего слота на указанную дату,
      # с длительностью из расписания (slot_duration_minutes) и в пределах рабочего дня
      def add_slot
        date = params[:date] ? Date.parse(params[:date]) : Date.current

        # Получаем все слоты на дату, отсортированные по времени начала
        existing_slots = current_user.time_slots.for_date(date).order(:start_time)

        if existing_slots.empty?
          return render_error(code: 'validation_error',
                              message: 'Нет существующих слотов для определения времени нового слота', status: :unprocessable_entity)
        end

        # Находим последний РАБОЧИЙ слот
        last_work_slot = existing_slots.where(slot_type: 'work').last
        unless last_work_slot
          return render_error(code: 'validation_error', message: 'Нет рабочих слотов для определения точки вставки',
                              status: :unprocessable_entity)
        end

        # Определяем длительность слота
        schedule = current_user.working_schedules.find_by(day_of_week: date.wday)
        slot_minutes = (schedule&.slot_duration_minutes || last_work_slot.duration_minutes).to_i
        slot_minutes = 60 if slot_minutes <= 0

        # Время начала — конец последнего рабочего слота (как минуты в сутках)
        start_m = (last_work_slot.end_time.hour * 60) + last_work_slot.end_time.min
        end_m = start_m + slot_minutes
        if end_m > 1440
          return render_error(code: 'validation_error', message: 'Нельзя добавлять слоты через полночь',
                              status: :unprocessable_entity)
        end

        end_m = [end_m, 1440].min

        to_hhmmss = ->(mins) { format('%02d:%02d:00', (mins / 60).floor, mins % 60) }
        new_start_hms = to_hhmmss.call(start_m)
        new_end_hms   = to_hhmmss.call(end_m)

        # Разрешаем добавлять слот и вне границ расписания.
        # Единственные ограничения: не пересекать полночь и не попадать на обед, если он задан и пересекается.
        # Уже проверили по минутам выше

        if schedule&.lunch_start && schedule.lunch_end && schedule.lunch_end > schedule.lunch_start
          lunch_s = (schedule.lunch_start.hour * 60) + schedule.lunch_start.min
          lunch_e = (schedule.lunch_end.hour * 60) + schedule.lunch_end.min
          if (start_m < lunch_e) && (end_m > lunch_s)
            return render_error(code: 'validation_error', message: 'Новый слот попадает на обед',
                                status: :unprocessable_entity)
          end
        end

        # Проверка пересечений с любыми слотами этого дня
        overlap = existing_slots.any? do |s|
          s_start_m = (s.start_time.hour * 60) + s.start_time.min
          s_end_m   = (s.end_time.hour * 60) + s.end_time.min
          (s_start_m < end_m) && (s_end_m > start_m)
        end
        if overlap
          return render_error(code: 'validation_error', message: 'Новый слот пересекается с существующими',
                              status: :unprocessable_entity)
        end

        # Создаем новый слот, записывая time как сырые HH:MM:SS
        new_slot = TimeSlot.create_with_raw_times!(
          user_id: current_user.id,
          date: date,
          start_time: new_start_hms,
          end_time: new_end_hms,
          duration_minutes: slot_minutes,
          is_available: true,
          slot_type: 'work',
          booking_id: nil
        )

        render json: {
          id: new_slot.id,
          start_time: new_slot.start_time.strftime('%H:%M'),
          end_time: new_slot.end_time.strftime('%H:%M'),
          duration_minutes: new_slot.duration_minutes,
          is_available: new_slot.is_available,
          slot_type: new_slot.slot_type,
          booked: new_slot.booked?,
          booking: nil
        }, status: :created
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
        return if current_user&.master?

        render_error(code: 'forbidden', message: 'Access denied. Masters only.',
                     status: :forbidden)
      end
    end
  end
end
