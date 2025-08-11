module Api
  module V1
    class WorkingSchedulesController < Api::V1::BaseController
      before_action :authenticate_user!
      before_action :ensure_master!

      def index
        schedules = current_user.working_schedules.order(:day_of_week)

        begin
          render json: schedules.map do |schedule|
            {
              id: schedule.id,
              day_of_week: schedule.day_of_week,
              day_name: schedule.day_name,
              is_working: schedule.is_working,
              start_time: schedule.start_time&.strftime('%H:%M'),
              end_time: schedule.end_time&.strftime('%H:%M'),
              lunch_start: schedule.lunch_start&.strftime('%H:%M'),
              lunch_end: schedule.lunch_end&.strftime('%H:%M'),
              slot_duration_minutes: schedule.slot_duration_minutes,
              total_slots_count: schedule.total_slots_count
            }
          end
        rescue StandardError => e
          Rails.logger.error "Error in WorkingSchedulesController#index: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { error: "Internal Server Error" }, status: :internal_server_error
        end
      end

      def show
        schedule = current_user.working_schedules.find(params[:id])

        render json: {
          id: schedule.id,
          day_of_week: schedule.day_of_week,
          day_name: schedule.day_name,
          is_working: schedule.is_working,
          start_time: schedule.start_time&.strftime('%H:%M'),
          end_time: schedule.end_time&.strftime('%H:%M'),
          lunch_start: schedule.lunch_start&.strftime('%H:%M'),
          lunch_end: schedule.lunch_end&.strftime('%H:%M'),
          slot_duration_minutes: schedule.slot_duration_minutes,
          total_slots_count: schedule.total_slots_count
        }
      end

      def update
        schedule = current_user.working_schedules.find(params[:id])

        # Логируем входящие данные
        Rails.logger.info "Updating schedule #{schedule.id} (day_of_week: #{schedule.day_of_week}) with params: #{schedule_params}"

        # Если день становится нерабочим, очищаем время
        update_params = schedule_params
        if update_params[:is_working] == false
          update_params[:start_time] = nil
          update_params[:end_time] = nil
          update_params[:lunch_start] = nil
          update_params[:lunch_end] = nil
          # НЕ очищаем slot_duration_minutes для нерабочих дней, так как валидация требует его
        end

        Rails.logger.info "Processed params: #{update_params}"

        # Используем транзакцию для атомарности
        ActiveRecord::Base.transaction do
          if schedule.update(update_params)
            Rails.logger.info "Schedule updated successfully: #{schedule.attributes}"

            # Удаляем старые слоты для этого дня недели
            Rails.logger.info "Clearing slots for day_of_week: #{schedule.day_of_week}"
            clear_slots_for_day_of_week(schedule.day_of_week)

            # Создаем новые слоты для будущих дат этого дня недели
            if schedule.is_working
              Rails.logger.info "Creating slots for day_of_week: #{schedule.day_of_week}"
              create_slots_for_day_of_week(schedule.day_of_week)
            else
              Rails.logger.info "Not creating slots for day_of_week: #{schedule.day_of_week} (not working day)"
            end

            render json: {
              id: schedule.id,
              day_of_week: schedule.day_of_week,
              day_name: schedule.day_name,
              is_working: schedule.is_working,
              start_time: schedule.start_time&.strftime('%H:%M'),
              end_time: schedule.end_time&.strftime('%H:%M'),
              lunch_start: schedule.lunch_start&.strftime('%H:%M'),
              lunch_end: schedule.lunch_end&.strftime('%H:%M'),
              slot_duration_minutes: schedule.slot_duration_minutes,
              total_slots_count: schedule.total_slots_count
            }
          else
            Rails.logger.error "Schedule update failed: #{schedule.errors.full_messages}"
            render json: { errors: schedule.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
        end
      rescue StandardError => e
        Rails.logger.error "Exception during schedule update: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { errors: ["Internal server error: #{e.message}"] }, status: :internal_server_error
      end

      private

      def schedule_params
        params.require(:working_schedule).permit(
          :is_working, :start_time, :end_time, :lunch_start, :lunch_end, :slot_duration_minutes
        )
      end

      def clear_slots_for_day_of_week(day_of_week)
        # Очищаем все будущие слоты для этого дня недели, начиная с текущей даты
        # Это важно, чтобы старые слоты для дня, который стал нерабочим, были удалены
        Rails.logger.info "Clearing ALL future slots for day #{day_of_week} from today onwards."

        # Используем правильный SQL для определения дня недели
        # PostgreSQL EXTRACT(DOW FROM date) возвращает 0=воскресенье, 1=понедельник, ..., 6=суббота
        current_user.time_slots
                    .where(date: Date.current..)
                    .where('EXTRACT(DOW FROM date) = ?', day_of_week)
                    .destroy_all
      end

      def create_slots_for_day_of_week(day_of_week)
        # Создаем слоты для будущих дат этого дня недели
        schedule = current_user.working_schedules.find_by(day_of_week: day_of_week)
        return unless schedule&.is_working

        Rails.logger.info "Creating slots for day #{day_of_week} with schedule: #{schedule.attributes}"

        dates_to_create = (0..30).map { |i| i.days.from_now.to_date }
                                 .select { |date| date.wday == day_of_week }

        Rails.logger.info "Creating slots for dates: #{dates_to_create}"

        dates_to_create.each do |date|
          Rails.logger.info "Processing date #{date} (wday: #{date.wday}) for slot creation."
          begin
            slots = schedule.generate_slots_for_date(date)
            Rails.logger.info "Generated #{slots.length} slots for #{date}"

            # Логируем каждый слот перед сохранением
            slots.each_with_index do |slot_data, index|
              Rails.logger.info "Slot #{index}: date=#{slot_data[:date]}, start=#{slot_data[:start_time]}, end=#{slot_data[:end_time]}, type=#{slot_data[:slot_type]}, is_available=#{slot_data[:is_available]}"
            end

            slots.each do |slot_data|
              current_user.time_slots.create!(slot_data.except(:user))
            end

            Rails.logger.info "Created #{slots.length} slots for #{date}"
          rescue StandardError => e
            Rails.logger.error "Error creating slots for #{date}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
      end

      def ensure_master!
        render json: { error: 'Access denied. Masters only.' }, status: :forbidden unless current_user&.master?
      end
    end
  end
end
