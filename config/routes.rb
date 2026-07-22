Rails.application.routes.draw do
  root "landing#index"
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "provider-platform", to: "landing#provider", as: :provider_platform
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
  get "places/autocomplete", to: "places#autocomplete", as: :places_autocomplete
  get "places/:place_id", to: "places#show", as: :place
  resources :care_profiles, only: %i[new create edit update]
  resources :reminders, only: %i[new create update]
  resources :service_requests, only: %i[new create update] do
    resource :completion, only: %i[show update], controller: "service_request_completions"
  end
  get "trusted-circle", to: "trusted_circle#index", as: :trusted_circle
  resources :profile_invitations, only: %i[create destroy]
  resources :care_profile_links, only: %i[update destroy]
  get "claim/:token", to: "profile_claims#show", as: :claim_profile
  post "claim/:token/request-code", to: "profile_claims#request_code", as: :claim_profile_request_code
  post "claim/:token", to: "profile_claims#create"

  scope "care-partner", as: "care_partner" do
    resource :session, controller: "care_partner_sessions", only: %i[new create destroy] do
      get :verify
      post :verify, to: "care_partner_sessions#confirm"
    end
  end

  namespace :care_partners, path: "care-partner" do
    root "dashboard#index"
    resource :onboarding, controller: "onboarding", only: %i[show update] do
      post :submit
    end
    patch "availability", to: "dashboard#availability", as: :availability
    resources :documents, only: %i[create destroy]
    resources :credentials, only: %i[create destroy]
    resources :services, only: %i[index create update destroy]
    resources :offers, only: :index do
      member do
        post :accept
        post :decline
      end
    end
    resources :assignments, only: %i[index show] do
      member do
        patch :check_in
        patch :start
        patch :submit_completion
      end
    end
    resources :earnings, only: :index
  end

  namespace :moderation do
    resources :care_partner_applications, only: %i[index show update]
    resources :earnings, only: %i[index update]
  end

  namespace :api do
    namespace :v1 do
      post "auth/request-code", to: "authentication#request_code"
      post "auth/sign-in", to: "authentication#sign_in"
      post "auth/sign-up", to: "authentication#sign_up"
      post "auth/refresh", to: "authentication#refresh"
      resource :push_token, only: %i[create destroy]
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
