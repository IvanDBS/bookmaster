class Api::V1::BookingsController < Api::V1::BaseController
  before_action :set_booking, only: [:show, :update_status, :destroy]
  before_action :ensure_booking_owner!, only: [:show, :update_status, :destroy]
  before_action :ensure_client!, only: [:create]

  def index
    @bookings = if current_user.master?
      # Для мастеров - только их записи
      current_user.bookings.includes(:service, :user).order(start_time: :desc)
    else
      # Для клиентов - только их записи с дополнительной проверкой
      Booking.includes(:service, :user)
             .where(client_email: current_user.email)
             .where.not(status: 'deleted') # Исключаем удаленные записи
             .order(created_at: :desc)
    end

    # Дополнительная проверка безопасности
    @bookings = @bookings.limit(1000) # Ограничиваем количество записей

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(@bookings, each_serializer: BookingPublicSerializer)
    }
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
      return render_error(code: 'validation_error', message: 'Услуга не найдена у выбранного мастера', 
                          status: :unprocessable_entity)
    end

    begin
      Booking.transaction do
        # Жесткая блокировка слота для предотвращения race conditions
        slot = master.time_slots.lock.find_by(id: params[:time_slot_id])
        return render_error(code: 'not_found', message: 'Слот не найден', status: :not_found) unless slot

        unless slot.can_be_booked?
          return render_error(code: 'validation_error', message: 'Слот недоступен для бронирования', 
                              status: :unprocessable_entity)
        end

        # Дополнительно запрещаем создавать бронь на слоты с типом lunch/blocked
        if %w[lunch blocked].include?(slot.slot_type)
          return render_error(code: 'validation_error', message: 'Нельзя бронировать перерыв/нерабочее время', 
                              status: :unprocessable_entity)
        end

        # Поддержка услуг длиннее одного слота: бронируем последовательность слотов
        # Кол-во слотов для услуги исходя из длительности услуги и длительности слота
        required_slots = (service.duration.to_f / slot.duration_minutes).ceil
        slots_chain = [slot]
        
        if required_slots > 1
          (1...required_slots).each do |i|
            # Рассчитываем ожидаемое время старта следующего слота в минутах от полуночи
            base_minutes = (slot.start_time.hour * 60) + slot.start_time.min
            expected_total = base_minutes + (i * slot.duration_minutes)
            exp_hour = (expected_total / 60) % 24
            exp_min  = expected_total % 60

            # Ищем следующий рабочий слот по совпадению часа и минуты начала
            next_slot = master.time_slots.for_date(slot.date)
                              .where(slot_type: 'work')
                              .find { |s| s.start_time.hour == exp_hour && s.start_time.min == exp_min }

            unless next_slot&.can_be_booked? && next_slot.slot_type == 'work'
              return render json: { error: 'Недостаточно последовательных свободных слотов для выбранной услуги' },
                            status: :unprocessable_entity
            end

            slots_chain << next_slot
          end
          
          # Блокируем все дополнительные слоты
          additional_slots = TimeSlot.where(id: slots_chain[1..].map(&:id)).lock.to_a
          unless additional_slots.size == slots_chain.size - 1
            raise ActiveRecord::Rollback, 'Не удалось заблокировать все необходимые слоты'
          end
          
          # Проверяем доступность всех дополнительных слотов
          additional_slots.each do |locked|
            unless locked.can_be_booked? && locked.slot_type == 'work'
              raise ActiveRecord::Rollback, 'Дополнительный слот уже занят или недоступен'
            end
          end
          
          slots_chain = [slot] + additional_slots
        end

        start_dt = Time.zone.parse("#{slot.date} #{slot.start_time.strftime('%H:%M')}")
        @booking = Booking.new(
          service: service,
          user: master,
          start_time: start_dt,
          end_time: start_dt + service.duration.minutes,
          status: 'pending',
          client_name: booking_params[:client_name].presence || 'Клиент',
          client_email: booking_params[:client_email].presence || 'client@example.com',
          client_phone: booking_params[:client_phone].presence || 'Не указан'
        )

        unless @booking.save
          raise ActiveRecord::Rollback, @booking.errors.full_messages.join(', ')
        end

        # Помечаем слоты занятыми в рамках той же транзакции под блокировкой
        slots_chain.each { |s| s.update!(booking: @booking, is_available: false) }
      end
    rescue StandardError => e
      return render_error(code: 'validation_error', message: e.message, status: :unprocessable_content)
    end

    # После создания — синхронизируем слоты, чтобы UI у мастера сразу показал занятость
    master.reconcile_bookings_with_slots_for_date(@booking.start_time.to_date)
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
        return render_error(code: 'validation_error', message: 'Нельзя подтвердить отмененную запись', 
                            status: :unprocessable_entity)
      end
      
      # Проверяем, что время записи еще не прошло
      if @booking.start_time < Time.current
        return render_error(code: 'validation_error', message: 'Нельзя подтвердить прошедшую запись', 
                            status: :unprocessable_entity)
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
      render_error(code: 'validation_error', message: @booking.errors.full_messages.join(', '), 
                   status: :unprocessable_entity)
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
        render_error(code: 'validation_error', message: @booking.errors.full_messages.join(', '), 
                     status: :unprocessable_entity)
      end
    rescue StandardError => e
      Rails.logger.error "Error destroying booking #{@booking.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render_error(code: 'internal_error', message: "Ошибка при удалении записи: #{e.message}", 
                   status: :internal_server_error)
    end
  end

  private

  def set_booking
    # Валидация ID - только цифры
    unless params[:id].to_s.match?(/\A\d+\z/)
      return render_error(code: 'bad_request', message: 'Неверный ID записи', status: :bad_request)
    end
    
    @booking = Booking.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error(code: 'not_found', message: 'Запись не найдена', status: :not_found)
  end

  def booking_params
    params.expect(booking: [:service_id, :client_name, :client_email, :client_phone])
  end

  def ensure_booking_owner!
    # Более строгая проверка прав доступа
    if current_user.master?
      # Мастер может видеть только свои брони
      unless @booking.user == current_user
        render_error(code: 'forbidden', message: 'Доступ запрещен', status: :forbidden)
      end
    else
      # Клиент может видеть только свои брони по email
      unless @booking.client_email == current_user.email
        render_error(code: 'forbidden', message: 'Доступ запрещен', status: :forbidden)
      end
    end
  end

  def ensure_client!
    # В текущей версии бронирование создают клиенты. Если потребуется — можно расширить до мастеров.
    return if current_user&.client?

    render_error(code: 'forbidden', message: 'Доступ запрещен. Только клиенты могут создавать бронирования.', 
                 status: :forbidden)
    
  end
end
