if Rails.env.production?
  Rails.application.configure do
    config.lograge.enabled = true
    config.lograge.keep_original_rails_log = false
    config.lograge.formatter = Lograge::Formatters::Json.new
    
    config.lograge.custom_options = lambda do |event|
      params = event.payload[:params] || {}
      
      # Фильтруем чувствительные данные
      filtered_params = params.except(
        'password', 'password_confirmation', 'token', 'authorization',
        'client_name', 'client_email', 'client_phone', 'email',
        'first_name', 'last_name', 'phone', 'bio', 'address',
        'jwt_token', 'confirmation_token', 'reset_password_token'
      )
      
      {
        time: Time.now.utc.iso8601,
        request_id: event.payload[:request_id],
        user_id: event.payload[:user_id],
        ip: event.payload[:ip],
        user_agent: event.payload[:user_agent],
        params: filtered_params,
        duration: event.duration.round(2),
        status: event.payload[:status],
        method: event.payload[:method],
        path: event.payload[:path]
      }
    end
  end
end

# Фильтрация чувствительных данных в обычных логах
Rails.application.configure do
  config.filter_parameters += [
    :password, :password_confirmation, :token, :authorization,
    :client_name, :client_email, :client_phone, :email,
    :first_name, :last_name, :phone, :bio, :address,
    :jwt_token, :confirmation_token, :reset_password_token
  ]
end
