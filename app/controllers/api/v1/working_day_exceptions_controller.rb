class Api::V1::WorkingDayExceptionsController < Api::V1::BaseController
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
      render json: { errors: @working_day_exception.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @working_day_exception.update(working_day_exception_params)
      render json: @working_day_exception
    else
      render json: { errors: @working_day_exception.errors }, status: :unprocessable_entity
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
    
    if exception
      # Исключение существует - переключаем статус
      exception.update!(is_working: !exception.is_working)
      render json: exception
    else
      # Исключения нет - создаем новое
      # Определяем, какой статус должен быть противоположным базовому расписанию
      schedule = current_user.working_schedules.find_by(day_of_week: date.wday)
      base_is_working = schedule&.is_working || false
      
      exception = current_user.working_day_exceptions.create!(
        date: date,
        is_working: !base_is_working,
        reason: params[:reason]
      )
      
      render json: exception, status: :created
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_working_day_exception
    @working_day_exception = current_user.working_day_exceptions.find(params[:id])
  end

  def working_day_exception_params
    params.require(:working_day_exception).permit(:date, :is_working, :reason)
  end
end