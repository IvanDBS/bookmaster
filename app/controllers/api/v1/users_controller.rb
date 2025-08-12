class Api::V1::UsersController < Api::V1::BaseController
  # Публичные эндпойнты для каталога мастеров
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @users = User.masters.includes(:services)

    if params[:category].present?
      @users = @users.joins(:services).where("LOWER(services.name) LIKE ?", "%#{params[:category].downcase}%")
    end

    render json: @users, each_serializer: UserPublicSerializer
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
      render_error(code: 'validation_error', message: current_user.errors.full_messages.join(', '), status: :unprocessable_entity)
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :bio, :address)
  end
end
