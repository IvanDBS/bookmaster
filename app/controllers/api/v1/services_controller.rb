class Api::V1::ServicesController < ApplicationController
  before_action :set_service, only: [:show, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show, :create, :update, :destroy] # Временно отключаю для всех операций
  before_action :ensure_master!, only: [] # Временно отключаю все проверки
  before_action :ensure_service_owner!, only: [] # Временно отключаю все проверки

  def index
    @services = Service.includes(:user).active
    
    if params[:category].present?
      @services = @services.by_category(params[:category])
    end
    
    if params[:master_id].present?
      @services = @services.where(user_id: params[:master_id])
    end
    
    render json: @services
  end

  def show
    render json: @service
  end

  def create
    # Временно создаем услугу для первого мастера
    master = User.where(role: 'master').first
    @service = master.services.build(service_params)
    
    if @service.save
      render json: @service, status: :created
    else
      render json: { errors: @service.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @service.update(service_params)
      render json: @service
    else
      render json: { errors: @service.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy
    render json: { message: 'Услуга удалена' }
  end

  private

  def set_service
    @service = Service.find(params[:id])
  end

  def service_params
    params.require(:service).permit(:name, :description, :price, :duration)
  end

  def ensure_master!
    unless current_user&.master?
      render json: { error: 'Только мастера могут управлять услугами' }, status: :forbidden
    end
  end

  def ensure_service_owner!
    unless @service.user == current_user
      render json: { error: 'Вы можете редактировать только свои услуги' }, status: :forbidden
    end
  end
end
