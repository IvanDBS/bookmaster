# frozen_string_literal: true

Rails.application.config.after_initialize do
  Warden::Manager.after_authentication do |user, auth, opts|
    # JWT токен будет установлен в auth controller
  end

  Warden::Manager.before_logout do |user, auth, opts|
    # JWT токен будет очищен в auth controller
  end
end
