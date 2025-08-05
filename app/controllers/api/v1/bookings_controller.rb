class Api::V1::BookingsController < ApplicationController
  before_action :set_booking, only: [:show, :update_status]
  before_action :authenticate_user!, except: [:create]
  before_action :ensure_booking_owner!, only: [:show, :update_status]

  def index
    @bookings = if current_user.master?
      current_user.bookings.includes(:service, :user)
    else
      Booking.where(client_email: current_user.email).includes(:service, :user)
    end
    
    @bookings = @bookings.order(start_time: :desc)
    
    render json: @bookings.as_json(include: { 
      service: { only: [:id, :name, :price, :duration] },
      user: { only: [:id, :first_name, :last_name, :phone] }
    })
  end

  def show
    render json: @booking.as_json(include: { 
      service: { only: [:id, :name, :price, :duration, :description] },
      user: { only: [:id, :first_name, :last_name, :phone, :bio] }
    })
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.user = User.masters.find_by(id: params[:master_id])
    
    unless @booking.user
      return render json: { error: 'Мастер не найден' }, status: :not_found
    end
    
    if @booking.save
      render json: @booking.as_json(include: { 
        service: { only: [:id, :name, :price, :duration] },
        user: { only: [:id, :first_name, :last_name, :phone] }
      }), status: :created
    else
      render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_status
    new_status = params[:status]
    
    unless %w[confirmed cancelled completed].include?(new_status)
      return render json: { error: 'Неверный статус' }, status: :bad_request
    end
    
    if @booking.update(status: new_status)
      render json: @booking
    else
      render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:service_id, :start_time, :client_name, :client_email, :client_phone)
  end

  def ensure_booking_owner!
    unless current_user.master? && @booking.user == current_user ||
           @booking.client_email == current_user.email
      render json: { error: 'Доступ запрещен' }, status: :forbidden
    end
  end
end
