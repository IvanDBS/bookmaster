module Api
  module V1
    class WorkingSchedulesController < Api::V1::BaseController
      before_action :ensure_master!

      def index
        # Возвращаем времена строго как строки 'HH:MM' из СУБД, без AR-тайпкастов
        schedules = current_user.working_schedules
                                .select("working_schedules.*, to_char(start_time,'HH24:MI') AS start_hhmm, to_char(end_time,'HH24:MI') AS end_hhmm, to_char(lunch_start,'HH24:MI') AS lunch_start_hhmm, to_char(lunch_end,'HH24:MI') AS lunch_end_hhmm")
                                .order(:day_of_week)

        begin
          render json: schedules.map do |schedule|
            {
              id: schedule.id,
              day_of_week: schedule.day_of_week,
              day_name: schedule.day_name,
              is_working: schedule.is_working,
              start_time: schedule.attributes['start_hhmm'].presence,
              end_time: schedule.attributes['end_hhmm'].presence,
              lunch_start: schedule.attributes['lunch_start_hhmm'].presence,
              lunch_end: schedule.attributes['lunch_end_hhmm'].presence,
              slot_duration_minutes: schedule.slot_duration_minutes,
              total_slots_count: schedule.total_slots_count
            }
          end
        rescue StandardError
          render_error(code: 'internal_error', message: 'Internal Server Error', status: :internal_server_error)
        end
      end

      def show
        schedule = current_user.working_schedules
                               .select("working_schedules.*, to_char(start_time,'HH24:MI') AS start_hhmm, to_char(end_time,'HH24:MI') AS end_hhmm, to_char(lunch_start,'HH24:MI') AS lunch_start_hhmm, to_char(lunch_end,'HH24:MI') AS lunch_end_hhmm")
                               .find(params[:id])

        render json: {
          id: schedule.id,
          day_of_week: schedule.day_of_week,
          day_name: schedule.day_name,
          is_working: schedule.is_working,
          start_time: schedule.attributes['start_hhmm'].presence,
          end_time: schedule.attributes['end_hhmm'].presence,
          lunch_start: schedule.attributes['lunch_start_hhmm'].presence,
          lunch_end: schedule.attributes['lunch_end_hhmm'].presence,
          slot_duration_minutes: schedule.slot_duration_minutes,
          total_slots_count: schedule.total_slots_count
        }
      end

      def update
        schedule = current_user.working_schedules.find(params[:id])

        # Если день становится нерабочим, очищаем время
        update_params = schedule_params
        # Принципиально НЕ конвертируем строки времени в Time,
        # чтобы исключить любые TZ-сдвиги. Отправляем в БД как 'HH:MM'.
        %i[start_time end_time lunch_start lunch_end].each do |key|
          val = update_params[key]
          next if val.nil? || val == ''

          if val.is_a?(String) && val.match?(/^\d{2}:\d{2}$/)
            # Пишем строго в локальной зоне, чтобы избежать UTC-сдвига на уровне Адаптера БД
            update_params[key] = Time.zone.parse("2000-01-01 #{val}:00").strftime('%H:%M')
          end
        end

        # Санитация: запрещаем переход через полночь и чистим обед, если он вне интервала
        if update_params[:is_working] != false &&
           update_params[:start_time].present? && update_params[:end_time].present?

          to_minutes = lambda do |hhmm|
            h, m = hhmm.split(':').map(&:to_i)
            (h * 60) + m
          end

          start_m = to_minutes.call(update_params[:start_time])
          end_m   = to_minutes.call(update_params[:end_time])
          # Жесткий запрет на переход через полночь
          if end_m <= start_m
            render_error(code: 'validation_error',
                         message: 'Интервалы не могут пересекать полночь. Время окончания должно быть позже начала в пределах одного дня.', status: :unprocessable_entity)
            return
          end

          if update_params[:lunch_start].present? && update_params[:lunch_end].present?
            lunch_s = to_minutes.call(update_params[:lunch_start])
            lunch_e = to_minutes.call(update_params[:lunch_end])
            unless lunch_s >= start_m && lunch_e <= end_m && lunch_e > lunch_s
              update_params[:lunch_start] = nil
              update_params[:lunch_end] = nil
            end
          end
        end
        if update_params[:is_working] == false
          update_params[:start_time] = nil
          update_params[:end_time] = nil
          update_params[:lunch_start] = nil
          update_params[:lunch_end] = nil
          # НЕ очищаем slot_duration_minutes для нерабочих дней, так как валидация требует его
        end

        # Подготавливаем сырые строки HH:MM:SS для прямой записи без AR-тайпкастинга time
        raw_time = ->(val) { val.present? ? format('%s:00', val.to_s) : nil }
        start_raw = raw_time.call(update_params[:start_time])
        end_raw   = raw_time.call(update_params[:end_time])
        lunch_s_raw = raw_time.call(update_params[:lunch_start])
        lunch_e_raw = raw_time.call(update_params[:lunch_end])

        # Используем транзакцию для атомарности
        ActiveRecord::Base.transaction do
          updated = false

          if update_params[:is_working] == false
            # Простая запись, все times = NULL
            updated = schedule.update_columns(
              is_working: false,
              start_time: nil,
              end_time: nil,
              lunch_start: nil,
              lunch_end: nil,
              slot_duration_minutes: nil,
              updated_at: Time.current
            )
          else
            # Валидация на уровне контроллера (без тайпкастов): end > start и обед внутри окна
            if start_raw && end_raw
              to_minutes = lambda { |hhmmss|
                hh, mm = hhmmss.split(':').map(&:to_i)
                (hh * 60) + mm
              }
              s = to_minutes.call(start_raw)
              e = to_minutes.call(end_raw)
              if e <= s
                return render_error(code: 'validation_error',
                                    message: 'Время окончания должно быть позже времени начала (один календарный день)', status: :unprocessable_entity)
              end

              if lunch_s_raw && lunch_e_raw
                ls = to_minutes.call(lunch_s_raw)
                le = to_minutes.call(lunch_e_raw)
                unless ls >= s && le <= e && le > ls
                  lunch_s_raw = nil
                  lunch_e_raw = nil
                end
              end
            end

            updated = schedule.update_columns(
              is_working: true,
              start_time: start_raw,
              end_time: end_raw,
              lunch_start: lunch_s_raw,
              lunch_end: lunch_e_raw,
              slot_duration_minutes: update_params[:slot_duration_minutes],
              updated_at: Time.current
            )
          end

          if updated
            schedule.reload

            # Удаляем старые слоты для этого дня недели
            clear_slots_for_day_of_week(schedule.day_of_week)

            # Создаем новые слоты для будущих дат этого дня недели
            create_slots_for_day_of_week(schedule.day_of_week) if schedule.is_working

            # Возвращаем сырые строки времени, чтобы фронт не страдал от TZ-сдвигов
            start_raw = schedule.read_attribute_before_type_cast(:start_time)
            end_raw   = schedule.read_attribute_before_type_cast(:end_time)
            lunch_s_raw = schedule.read_attribute_before_type_cast(:lunch_start)
            lunch_e_raw = schedule.read_attribute_before_type_cast(:lunch_end)
            render json: {
              id: schedule.id,
              day_of_week: schedule.day_of_week,
              day_name: schedule.day_name,
              is_working: schedule.is_working,
              start_time: start_raw&.to_s&.slice(0, 5),
              end_time: end_raw&.to_s&.slice(0, 5),
              lunch_start: lunch_s_raw&.to_s&.slice(0, 5),
              lunch_end: lunch_e_raw&.to_s&.slice(0, 5),
              slot_duration_minutes: schedule.slot_duration_minutes,
              total_slots_count: schedule.total_slots_count
            }
          else
            render_error(code: 'validation_error', message: schedule.errors.full_messages.join(', '),
                         status: :unprocessable_entity)
            raise ActiveRecord::Rollback
          end
        end
      rescue StandardError
        render_error(code: 'internal_error', message: 'Internal Server Error', status: :internal_server_error)
      end

      private

      def schedule_params
        params.expect(
          working_schedule: [:is_working, :start_time, :end_time, :lunch_start, :lunch_end, :slot_duration_minutes]
        )
      end

      def clear_slots_for_day_of_week(day_of_week)
        # Очищаем все будущие слоты для этого дня недели, начиная с текущей даты
        # Это важно, чтобы старые слоты для дня, который стал нерабочим, были удалены

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

        dates_to_create = (0..30).map { |i| i.days.from_now.to_date }
                                 .select { |date| date.wday == day_of_week }

        dates_to_create.each do |date|
          slots = schedule.generate_slots_for_date(date)

          slots.each do |slot_data|
            # Пишем time поля как сырые HH:MM:SS, исключая TZ каст
            TimeSlot.create_with_raw_times!(
              user_id: current_user.id,
              date: slot_data[:date],
              start_time: slot_data[:start_time],
              end_time: slot_data[:end_time],
              duration_minutes: slot_data[:duration_minutes],
              is_available: slot_data[:is_available],
              slot_type: slot_data[:slot_type],
              booking_id: nil
            )
          end
        rescue StandardError
          # Silent error handling for production
        end
      end

      def ensure_master!
        return if current_user&.master?

        render_error(code: 'forbidden', message: 'Access denied. Masters only.',
                     status: :forbidden)
      end
    end
  end
end
