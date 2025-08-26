module Api
  module V1
    class WorkingDayExceptionsController < Api::V1::BaseController
      before_action :ensure_master!
      before_action :set_working_day_exception, only: [:show, :update, :destroy]

      def index
        @working_day_exceptions = current_user.working_day_exceptions.order(:date)
        render json: @working_day_exceptions
      end

      def show
        render json: @working_day_exception
      end

      def create
        @working_day_exception = current_user.working_day_exceptions.build(working_day_exception_params)

        if @working_day_exception.save
          render json: @working_day_exception, status: :created
        else
          render_error(code: 'validation_error', message: @working_day_exception.errors.full_messages.join(', '),
                       status: :unprocessable_entity)
        end
      end

      def update
        if @working_day_exception.update(working_day_exception_params)
          render json: @working_day_exception
        else
          render_error(code: 'validation_error', message: @working_day_exception.errors.full_messages.join(', '),
                       status: :unprocessable_entity)
        end
      end

      def destroy
        @working_day_exception.destroy
        head :no_content
      end

      # Специальный метод для переключения статуса дня
      def toggle
        begin
          date = params[:date].present? ? Date.parse(params[:date].to_s) : nil
        rescue ArgumentError
          return render_error(code: 'validation_error', message: 'Некорректная дата', status: :unprocessable_entity)
        end
        unless date
          return render_error(code: 'validation_error', message: 'Дата не передана',
                              status: :unprocessable_entity)
        end

        exception = current_user.working_day_exceptions.find_by(date: date)

        schedule = current_user.working_schedules.find_by(day_of_week: date.wday)
        base_is_working = schedule&.is_working || false
        target_is_working = if exception
                              !exception.is_working
                            else
                              !base_is_working
                            end

        # Если хотим сделать день выходным, проверим, нет ли активных записей
        if target_is_working == false
          active_bookings = Booking.where(user_id: current_user.id,
                                          start_time: date.all_day,
                                          status: %w[pending confirmed])
          if active_bookings.exists?
            return render_error(code: 'validation_error',
                                message: 'Нельзя сделать день выходным: на эту дату есть активные записи',
                                status: :unprocessable_entity)
          end
        end

        if exception
          exception.update!(is_working: target_is_working, reason: params[:reason] || exception.reason)
        else
          exception = current_user.working_day_exceptions.create!(
            date: date,
            is_working: target_is_working,
            reason: params[:reason]
          )
        end

        # Обновляем слоты в соответствии с новым статусом дня
        if target_is_working
          # Убеждаемся, что есть валидное расписание на этот день (без перехода через полночь)
          schedule ||= current_user.working_schedules.find_or_initialize_by(day_of_week: date.wday)

          # База (шаблон) для времени: первый рабочий день пользователя
          template = current_user.working_schedules.working_days
                                 .where('start_time IS NOT NULL AND end_time IS NOT NULL')
                                 .order(:day_of_week)
                                 .first

          # Если базовый день был НЕрабочим, не доверяем его старым часам — выставляем из шаблона или дефолт 09:00–18:00
          if schedule.is_working == false
            schedule.start_time = (template&.start_time || '09:00')
            schedule.end_time   = (template&.end_time   || '18:00')
            schedule.slot_duration_minutes ||= template&.slot_duration_minutes || 60
          else
            # Если часы отсутствуют — также подставляем из шаблона/дефолта
            if schedule.start_time.blank? || schedule.end_time.blank?
              schedule.start_time ||= template&.start_time || '09:00'
              schedule.end_time   ||= template&.end_time   || '18:00'
            end
            schedule.slot_duration_minutes ||= schedule.slot_duration_minutes.presence || template&.slot_duration_minutes || 60
          end

          schedule.is_working = true

          # Если ланч вне интервала или некорректен — очищаем
          if schedule.lunch_start && schedule.lunch_end && (schedule.end_time <= schedule.start_time || schedule.lunch_end <= schedule.lunch_start ||
               schedule.lunch_start < schedule.start_time || schedule.lunch_end > schedule.end_time)
            schedule.lunch_start = nil
            schedule.lunch_end = nil
          end

          # Принудительно валидируем бизнес-правило: end_time > start_time
          if schedule.end_time <= schedule.start_time
            schedule.start_time = '09:00'
            schedule.end_time   = '18:00'
          end

          schedule.save!
          # Становится рабочим — генерируем слоты и синхронизируем
          current_user.ensure_slots_for_date(date)
        else
          # Становится выходным — удаляем все свободные слоты на дату
          current_user.time_slots.for_date(date).where(booking_id: nil).delete_all
        end

        render json: exception, status: (exception.previously_new_record? ? :created : :ok)
      rescue StandardError => e
        render_error(code: 'validation_error', message: e.message, status: :unprocessable_entity)
      end

      private

      def set_working_day_exception
        @working_day_exception = current_user.working_day_exceptions.find(params[:id])
      end

      def working_day_exception_params
        params.expect(working_day_exception: [:date, :is_working, :reason])
      end

      def ensure_master!
        return if current_user&.master?

        render_error(code: 'forbidden', message: 'Access denied. Masters only.',
                     status: :forbidden)
      end
    end
  end
end
