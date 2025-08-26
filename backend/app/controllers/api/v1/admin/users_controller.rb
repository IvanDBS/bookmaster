module Api
  module V1
    module Admin
      class UsersController < Api::V1::Admin::BaseController
        before_action :set_user, only: [:update, :destroy]

        def index
          users = User.order(created_at: :desc)
          if params[:query].present?
            q = "%#{params[:query].downcase}%"
            users = users.where('LOWER(email) LIKE ? OR LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ?', q, q, q)
          end
          page = params[:page].to_i
          page = 1 if page <= 0
          per_page = params[:per_page].to_i
          per_page = 20 if per_page <= 0 || per_page > 100
          total = users.count
          users = users.offset((page - 1) * per_page).limit(per_page)
          render json: {
            data: ActiveModelSerializers::SerializableResource.new(users, each_serializer: UserSerializer),
            meta: { page: page, per_page: per_page, total: total }
          }
        end

        def update
          if @user.update(user_params)
            render json: { data: UserSerializer.new(@user).as_json }
          else
            render_error(code: 'validation_error', message: @user.errors.full_messages.join(', '),
                         status: :unprocessable_entity)
          end
        end

        def destroy
          id = @user.id
          if @user.id == current_user.id
            return render_error(code: 'forbidden', message: 'Нельзя удалить собственную учетную запись',
                                status: :forbidden)
          end

          if @user.destroy
            render json: { data: { id: id, message: 'Пользователь удален' } }
          else
            render_error(code: 'validation_error', message: @user.errors.full_messages.join(', '),
                         status: :unprocessable_entity)
          end
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          params.expect(user: [:role, :first_name, :last_name, :phone])
        end
      end
    end
  end
end
