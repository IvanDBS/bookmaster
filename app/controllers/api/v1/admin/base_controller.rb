class Api::V1::Admin::BaseController < Api::V1::BaseController
  before_action :ensure_admin!

  private

  def ensure_admin!
    unless current_user&.admin?
      render_error(code: 'forbidden', message: 'Доступ запрещен. Только администраторы.', status: :forbidden)
    end
  end
end


