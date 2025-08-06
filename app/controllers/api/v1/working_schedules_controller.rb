class Api::V1::WorkingSchedulesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :ensure_master!

  def index
    schedules = current_user.working_schedules.order(:day_of_week)
    
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
    
    if schedule.update(schedule_params)
      # Удаляем старые слоты для этого дня недели
      clear_slots_for_day_of_week(schedule.day_of_week)
      
      # Создаем новые слоты для будущих дат этого дня недели
      if schedule.is_working
        create_slots_for_day_of_week(schedule.day_of_week)
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
      render json: { errors: schedule.errors }, status: :unprocessable_entity
    end
  end

  private

  def schedule_params
    params.require(:working_schedule).permit(
      :is_working, :start_time, :end_time, :lunch_start, :lunch_end, :slot_duration_minutes
    )
  end

  def clear_slots_for_day_of_week(day_of_week)
    # Очищаем слоты только для будущих дат этого дня недели
    dates_to_clear = (0..30).map { |i| i.days.from_now.to_date }
                             .select { |date| date.wday == day_of_week }
    
    dates_to_clear.each do |date|
      current_user.time_slots.for_date(date).destroy_all
    end
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
        current_user.time_slots.create!(slot_data.except(:user))
      end
    end
  end

  def ensure_master!
    render json: { error: 'Access denied. Masters only.' }, status: :forbidden unless current_user&.master?
  end
end