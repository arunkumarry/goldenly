Rails.application.routes.draw do
  root "dashboard#index"
  resource :session, only: %i[new create destroy] do
    get :verify
    post :verify, to: "sessions#confirm"
  end
  resources :users, only: %i[new create] do
    collection do
      get :verify
      post :verify, to: "users#confirm"
    end
  end
  resource :profile, only: %i[edit update]
  patch "active-care-profile", to: "care_profile_selections#update", as: :active_care_profile
  get "care-timeline", to: "dashboard#timeline", as: :care_timeline
  get "calendar", to: "dashboard#calendar", as: :calendar
  get "services", to: "dashboard#services", as: :services
  post "assistant/messages", to: "assistant_messages#create", as: :assistant_messages
  post "assistant/actions/confirm", to: "assistant_messages#confirm", as: :confirm_assistant_action
  resources :care_profiles, only: %i[new create edit update]
  resources :reminders, only: %i[new create update]
  resources :service_requests, only: %i[new create update]
  get "trusted-circle", to: "trusted_circle#index", as: :trusted_circle
  resources :profile_invitations, only: %i[create destroy]
  resources :care_profile_links, only: %i[update destroy]
  get "claim/:token", to: "profile_claims#show", as: :claim_profile
  post "claim/:token/request-code", to: "profile_claims#request_code", as: :claim_profile_request_code
  post "claim/:token", to: "profile_claims#create"

  namespace :api do
    namespace :v1 do
      post "auth/request-code", to: "authentication#request_code"
      post "auth/sign-in", to: "authentication#sign_in"
      post "auth/sign-up", to: "authentication#sign_up"
      post "auth/refresh", to: "authentication#refresh"
      resources :care_profiles, only: %i[index create]
      post "care-agent/messages", to: "care_agent#message"
      post "care-agent/actions/confirm", to: "care_agent#confirm"
      resource :dashboard, only: :show
      resources :service_catalogs, only: :index
      resources :service_requests, only: %i[index create]
      resources :reminders, only: %i[index create]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
