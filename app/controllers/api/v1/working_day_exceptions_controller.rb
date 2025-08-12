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
          render_error(code: 'validation_error', message: @working_day_exception.errors.full_messages.join(', '), status: :unprocessable_entity)
        end
      end

      def update
        if @working_day_exception.update(working_day_exception_params)
          render json: @working_day_exception
        else
          render_error(code: 'validation_error', message: @working_day_exception.errors.full_messages.join(', '), status: :unprocessable_entity)
        end
      end

      def destroy
        @working_day_exception.destroy
        head :no_content
      end

      # Специальный метод для переключения статуса дня
      def toggle
        date = params[:date].to_date

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
          # Убеждаемся, что у расписания на этот день заданы часы и длительность слота
          schedule ||= current_user.working_schedules.find_or_initialize_by(day_of_week: date.wday)
          if schedule.start_time.blank? || schedule.end_time.blank? || schedule.slot_duration_minutes.blank?
            # Пытаемся скопировать шаблон с ближайшего рабочего дня
            template = current_user.working_schedules.working_days
                                   .where('start_time IS NOT NULL AND end_time IS NOT NULL')
                                   .order(:day_of_week)
                                   .first
            schedule.start_time ||= template&.start_time || '09:00'
            schedule.end_time   ||= template&.end_time   || '18:00'
            schedule.lunch_start ||= template&.lunch_start || '13:00'
            schedule.lunch_end   ||= template&.lunch_end   || '14:00'
            schedule.slot_duration_minutes ||= template&.slot_duration_minutes || 30
            schedule.is_working = true
            schedule.save!
          end
          # Становится рабочим — генерируем слоты и синхронизируем
          current_user.ensure_slots_for_date(date)
        else
          # Становится выходным — удаляем все свободные слоты на дату
          current_user.time_slots.for_date(date).where(booking_id: nil).delete_all
        end

        render json: exception, status: :ok
      rescue StandardError => e
        render_error(code: 'validation_error', message: e.message, status: :unprocessable_entity)
      end

      private

      def set_working_day_exception
        @working_day_exception = current_user.working_day_exceptions.find(params[:id])
      end

      def working_day_exception_params
        params.require(:working_day_exception).permit(:date, :is_working, :reason)
      end

      def ensure_master!
        render_error(code: 'forbidden', message: 'Access denied. Masters only.', status: :forbidden) unless current_user&.master?
      end
    end
  end
end
