module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :ensure_admin!

        private

        def ensure_admin!
          return if current_user&.admin?

          render_error(code: 'forbidden', message: 'Доступ запрещен. Только администраторы.', status: :forbidden)
        end
      end
    end
  end
end
