class Api::V1::UsersController < Api::V1::BaseController
  # Публичные эндпойнты для каталога мастеров
  skip_before_action :authenticate_user_from_jwt!, only: [:index, :show]

  def index
    @users = User.masters.includes(:services)

    if params[:category].present?
      @users = @users.joins(:services).where("LOWER(services.name) LIKE ?", "%#{params[:category].downcase}%")
    end

    # Убираем дубликаты после join
    @users = @users.distinct

    # Опциональная пагинация. Если page/per_page заданы — возвращаем с метаданными,
    # иначе сохраняем обратную совместимость (возвращаем массив пользователей)
    if params[:page].present? || params[:per_page].present?
      page = params[:page].to_i
      per_page = params[:per_page].to_i
      page = 1 if page <= 0
      per_page = 20 if per_page <= 0 || per_page > 100

      total = @users.count
      @users = @users.offset((page - 1) * per_page).limit(per_page)

      render json: {
        users: ActiveModelSerializers::SerializableResource.new(@users, each_serializer: UserPublicSerializer),
        meta: { page: page, per_page: per_page, total: total }
      }
    else
      render json: @users, each_serializer: UserPublicSerializer
    end
  end

  def show
    @user = User.masters.find(params[:id])
    # Если смотрит владелец (мастер) — отдаём private профиль, иначе public
    if current_user&.id == @user.id
      render json: @user, serializer: UserPrivateSerializer
    else
      render json: @user, serializer: UserPublicSerializer
    end
  end

  def update
    if current_user.update(user_params)
      render json: current_user.as_json(only: [:id, :email, :first_name, :last_name, :role, :phone, :bio, :address])
    else
      render_error(code: 'validation_error', message: current_user.errors.full_messages.join(', '), 
                   status: :unprocessable_entity)
    end
  end

  private

  def user_params
    params.expect(user: [:first_name, :last_name, :phone, :bio, :address])
  end
end
