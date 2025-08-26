Rails.application.routes.draw do
  # Keep Devise routes disabled in production API-only mode.
  # Re-enable minimal mapping in test/development to support Devise test helpers (sign_in, etc.).
  if Rails.env.test? || Rails.env.development?
    devise_for :users, skip: [:sessions, :registrations, :passwords], controllers: {
      confirmations: 'users/confirmations'
    }
  end
  
  # API routes
  namespace :api do
    namespace :v1 do
      namespace :admin do
        resources :users, only: [:index, :update, :destroy]
      end
      # Auth routes
      post '/auth/register', to: 'auth#register'
      post '/auth/login', to: 'auth#login'
      post '/auth/confirm', to: 'auth#confirm'
      post '/auth/resend_confirmation', to: 'auth#resend_confirmation'
      post '/auth/google', to: 'auth#google'
      get '/auth/google_fedcm', to: 'auth#google_fedcm'
      get '/auth/google_callback', to: 'auth#google_callback'
      delete '/auth/logout', to: 'auth#logout'
      get '/auth/profile', to: 'auth#profile'
      
      # GDPR compliance routes
      get '/auth/export_data', to: 'auth#export_data'
      delete '/auth/delete_account', to: 'auth#delete_account'
      post '/auth/restore_account', to: 'auth#restore_account'
      
      # GDPR controller routes
      get '/gdpr/consent_status', to: 'gdpr#consent_status'
      post '/gdpr/export_data', to: 'gdpr#export_data'
      post '/gdpr/request_deletion', to: 'gdpr#request_deletion'
      post '/gdpr/cancel_deletion', to: 'gdpr#cancel_deletion'
      post '/gdpr/give_consent', to: 'gdpr#give_consent'
      post '/gdpr/revoke_consent', to: 'gdpr#revoke_consent'
      post '/gdpr/give_marketing_consent', to: 'gdpr#give_marketing_consent'
      post '/gdpr/revoke_marketing_consent', to: 'gdpr#revoke_marketing_consent'
      
      # Users routes
      resources :users, only: [:index, :show, :update]
      
      # Services routes
      resources :services, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :service_types
        end
      end
      
      # Bookings routes
      resources :bookings, only: [:index, :show, :create, :destroy] do
        member do
          patch :update_status
        end
      end
      
      # Time slots routes
      resources :time_slots, only: [:index, :show, :update] do
        collection do
          # Публичная выдача слотов для мастера по дате (для клиента)
          get :public, to: 'time_slots#public_index'
          # Добавление нового слота после последнего на дату
          post :add_slot, to: 'time_slots#add_slot'
        end
      end
      
      # Working schedules routes
      resources :working_schedules, only: [:index, :show, :update]
      
      # Working day exceptions routes
      resources :working_day_exceptions, only: [:index, :show, :create, :update, :destroy] do
        collection do
          post 'toggle', to: 'working_day_exceptions#toggle'
        end
      end
    end
  end

  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'

    # Letter Opener web UI to preview sent emails
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  if Rails.env.production?
    require 'sidekiq/web'
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('SIDEKIQ_WEB_USER', 'admin')) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_WEB_PASSWORD', 'change-me'))
    end
    mount Sidekiq::Web => '/sidekiq'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
