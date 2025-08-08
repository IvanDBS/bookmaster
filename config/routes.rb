Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'devise/sessions',
    registrations: 'devise/registrations'
  }
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Auth routes
      post '/auth/register', to: 'auth#register'
      post '/auth/login', to: 'auth#login'
      delete '/auth/logout', to: 'auth#logout'
      get '/auth/profile', to: 'auth#profile'
      
      # Users routes
      resources :users, only: [:index, :show, :update]
      
      # Services routes
      resources :services, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :service_types
        end
      end
      
      # Bookings routes
      resources :bookings, only: [:index, :show, :create] do
        member do
          patch :update_status
        end
      end
      
      # Time slots routes
      resources :time_slots, only: [:index, :show, :update] do
        collection do
          # Публичная выдача слотов для мастера по дате (для клиента)
          get :public, to: 'time_slots#public_index'
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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
