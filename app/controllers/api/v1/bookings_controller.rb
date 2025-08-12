class Api::V1::BookingsController < Api::V1::BaseController
  before_action :set_booking, only: [:show, :update_status, :destroy]
  before_action :authenticate_user!
  before_action :ensure_booking_owner!, only: [:show, :update_status, :destroy]
  before_action :ensure_client!, only: [:create]

  def index
    @bookings = if current_user.master?
      # Для мастеров: отдаем записи + ближайшие слоты как справку (UI сам может игнорировать)
      current_user.bookings.includes(:service).order(start_time: :desc)
    else
      # Для клиентов показываем записи где они клиенты, сортируем по дате создания (новые сверху)
      Booking.includes(:service, :user)
             .where(client_email: current_user.email)
             .order(created_at: :desc)
                end
    
    render json: @bookings, each_serializer: BookingPublicSerializer
  end

  def show
    render json: @booking, serializer: BookingPublicSerializer
  end

  # Клиент создает бронирование, указывая master_id, service_id и time_slot_id
  # Бронирование атомарно привязывается к слоту и помечает слот занятым
  def create
    master = User.masters.find_by(id: params[:master_id])
    return render_error(code: 'not_found', message: 'Мастер не найден', status: :not_found) unless master

    service = master.services.find_by(id: booking_params[:service_id])
    unless service
      return render_error(code: 'validation_error', message: 'Услуга не найдена у выбранного мастера', status: :unprocessable_entity)
    end

    slot = master.time_slots.find_by(id: params[:time_slot_id])
    return render_error(code: 'not_found', message: 'Слот не найден', status: :not_found) unless slot

    unless slot.can_be_booked?
      return render_error(code: 'validation_error', message: 'Слот недоступен для бронирования', status: :unprocessable_entity)
    end

    # Дополнительно запрещаем создавать бронь на слоты с типом lunch/blocked
    if %w[lunch blocked].include?(slot.slot_type)
      return render_error(code: 'validation_error', message: 'Нельзя бронировать перерыв/нерабочее время', status: :unprocessable_entity)
    end

    # Поддержка услуг длиннее одного слота: бронируем последовательность слотов
    # Кол-во слотов для услуги исходя из длительности услуги и длительности слота
    required_slots = (service.duration.to_f / slot.duration_minutes).ceil
    slots_chain = [slot]
    if required_slots > 1
      (1...required_slots).each do |i|
        expected_start = Time.zone.parse("2000-01-01 #{slot.start_time.strftime('%H:%M')}") + (i * slot.duration)
        next_slot = master.time_slots.for_date(slot.date)
                          .find_by(start_time: expected_start, slot_type: 'work')
        unless next_slot&.can_be_booked? && next_slot.slot_type == 'work'
          return render json: { error: 'Недостаточно последовательных свободных слотов для выбранной услуги' }, 
                        status: :unprocessable_entity
        end

        slots_chain << next_slot
      end
    end

    begin
      Booking.transaction do
        # Жёсткая блокировка всех слотов цепочки до конца транзакции
        locked_slots = TimeSlot.where(id: slots_chain.map(&:id)).lock.to_a

        # Проверяем, что все ожидаемые слоты реально заблокированы и ещё доступны для брони
        unless locked_slots.size == slots_chain.size
          raise ActiveRecord::Rollback, 'Не удалось заблокировать все необходимые слоты'
        end

        locked_slots.each do |locked|
          unless locked.can_be_booked? && locked.slot_type == 'work'
            raise ActiveRecord::Rollback, 'Слот уже занят или недоступен'
          end
        end

        start_dt = Time.zone.parse("#{slot.date} #{slot.start_time.strftime('%H:%M')}")
        @booking = Booking.new(
          service: service,
          user: master,
          start_time: start_dt,
          end_time: start_dt + service.duration.minutes,
          client_name: booking_params[:client_name].presence || current_user&.full_name || 'Клиент',
          client_email: current_user&.email || 'client@example.com',
          client_phone: booking_params[:client_phone].presence || current_user&.phone
        )

        unless @booking.save
          raise ActiveRecord::Rollback, @booking.errors.full_messages.join(', ')
        end

        # Помечаем слоты занятыми в рамках той же транзакции под блокировкой
        locked_slots.each { |s| s.update!(booking: @booking, is_available: false) }
      end
    rescue StandardError => e
      return render_error(code: 'validation_error', message: e.message, status: :unprocessable_entity)
    end

    # После создания — синхронизируем слоты, чтобы UI у мастера сразу показал занятость
    master.reconcile_bookings_with_slots_for_date(slot.date)
    render json: @booking, status: :created
  end

  def update_status
    new_status = params[:status]
    
    unless %w[confirmed cancelled completed].include?(new_status)
      return render_error(code: 'bad_request', message: 'Неверный статус', status: :bad_request)
    end
    
    # При подтверждении проверяем только базовые условия
    if new_status == 'confirmed'
      # Проверяем, что запись еще не подтверждена
      if @booking.confirmed?
        return render_error(code: 'validation_error', message: 'Запись уже подтверждена', status: :unprocessable_entity)
      end
      
      # Проверяем, что запись не отменена
      if @booking.cancelled?
        return render_error(code: 'validation_error', message: 'Нельзя подтвердить отмененную запись', status: :unprocessable_entity)
      end
      
      # Проверяем, что время записи еще не прошло
      if @booking.start_time < Time.current
        return render_error(code: 'validation_error', message: 'Нельзя подтвердить прошедшую запись', status: :unprocessable_entity)
      end
    end

    if @booking.update(status: new_status)
      # Освобождаем слот при отмене
      if new_status == 'cancelled'
        # Находим все слоты связанные с этой записью и освобождаем их
        TimeSlot.where(booking_id: @booking.id).update_all(booking_id: nil, is_available: true, 
                                                           updated_at: Time.current)
        # Запускаем синхронизацию для обновления данных
      else
        # На подтверждение/завершение — убедиться, что слоты помечены занятыми
        # Запускаем полную синхронизацию для правильной связи
      end
      @booking.user.reconcile_bookings_with_slots_for_date(@booking.start_time.to_date)
      render json: @booking
    else
      render_error(code: 'validation_error', message: @booking.errors.full_messages.join(', '), status: :unprocessable_entity)
    end
  end

  def destroy
    unless @booking
      return render_error(code: 'not_found', message: 'Запись не найдена', status: :not_found)
    end
    
    # Сохраняем ссылки до удаления
    user = @booking.user
    date = @booking.start_time.to_date
    
    begin
      if @booking.destroy
        # Освобождаем слоты связанные с этой записью
        TimeSlot.where(booking_id: @booking.id).update_all(booking_id: nil, is_available: true, 
                                                           updated_at: Time.current)
        # Запускаем синхронизацию для обновления данных
        user.reconcile_bookings_with_slots_for_date(date)
        render json: { message: 'Запись успешно удалена' }
      else
        render_error(code: 'validation_error', message: @booking.errors.full_messages.join(', '), status: :unprocessable_entity)
      end
    rescue StandardError => e
      Rails.logger.error "Error destroying booking #{@booking.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render_error(code: 'internal_error', message: "Ошибка при удалении записи: #{e.message}", status: :internal_server_error)
    end
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:service_id, :client_name, :client_email, :client_phone)
  end

  def ensure_booking_owner!
    unless (current_user.master? && @booking.user == current_user) ||
           @booking.client_email == current_user.email
      render_error(code: 'forbidden', message: 'Доступ запрещен', status: :forbidden)
    end
  end

  def ensure_client!
    # В текущей версии бронирование создают клиенты. Если потребуется — можно расширить до мастеров.
    render_error(code: 'forbidden', message: 'Доступ запрещен. Только клиенты могут создавать бронирования.', status: :forbidden) unless current_user&.client?
  end
end
