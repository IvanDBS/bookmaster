class Api::V1::ServicesController < Api::V1::BaseController
  before_action :set_service, only: [:show, :update, :destroy]
  skip_before_action :authenticate_user_from_jwt!, only: [:index, :show, :service_types]
  before_action :ensure_master!, only: [:create, :update, :destroy]
  before_action :ensure_service_owner!, only: [:update, :destroy]

  def index
    @services = Service.includes(:user).active
    
    if params[:category].present?
      @services = @services.by_category(params[:category])
    end
    
    if params[:service_type].present?
      @services = @services.by_service_type(params[:service_type])
    end
    
    if params[:master_id].present?
      @services = @services.where(user_id: params[:master_id])
    end
    
    # Если нужен только список услуг текущего мастера — используйте параметр mine=true
    if params[:mine].present? && ActiveModel::Type::Boolean.new.cast(params[:mine])
      if respond_to?(:current_user) && current_user&.master?
        @services = @services.where(user_id: current_user.id)
      else
        return render_error(code: 'forbidden', message: 'Только мастера могут запрашивать свои услуги', 
                            status: :forbidden)
      end
    end
    
    # Пагинация по запросу (опционально). Если page/per_page заданы — возвращаем с метаданными,
    # иначе — совместимость с текущим фронтом (простой массив)
    if params[:page].present? || params[:per_page].present?
      page = params[:page].to_i
      per_page = params[:per_page].to_i
      page = 1 if page <= 0
      per_page = 20 if per_page <= 0 || per_page > 100

      total = @services.count
      @services = @services.offset((page - 1) * per_page).limit(per_page)

      render json: {
        services: ActiveModelSerializers::SerializableResource.new(@services, each_serializer: ServicePublicSerializer),
        meta: { page: page, per_page: per_page, total: total }
      }
    else
      render json: @services, each_serializer: ServicePublicSerializer
    end
  end

  def show
    render json: @service, serializer: ServicePublicSerializer
  end

  def service_types
    render json: { service_types: Service.available_service_types }
  end

  def create
    @service = (respond_to?(:current_user) ? current_user : nil)&.services&.build(service_params)
    
    if @service.save
      render json: @service, serializer: ServicePublicSerializer, status: :created
    else
      render_error(code: 'validation_error', message: @service.errors.full_messages.join(', '), 
                   status: :unprocessable_entity)
    end
  end

  def update
    if @service.update(service_params)
      render json: @service, serializer: ServicePublicSerializer
    else
      render_error(code: 'validation_error', message: @service.errors.full_messages.join(', '), 
                   status: :unprocessable_entity)
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
    params.expect(service: [:name, :description, :price, :duration, :service_type])
  end

  def ensure_master!
    unless respond_to?(:current_user) && current_user&.master?
      render_error(code: 'forbidden', message: 'Только мастера могут управлять услугами', status: :forbidden)
    end
  end

  def ensure_service_owner!
    unless respond_to?(:current_user) && @service.user == current_user
      render_error(code: 'forbidden', message: 'Вы можете редактировать только свои услуги', status: :forbidden)
    end
  end
end
