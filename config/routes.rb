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
  patch "active-member", to: "member_selections#update", as: :active_member
  get "care-timeline", to: "dashboard#timeline", as: :care_timeline
  get "services", to: "dashboard#services", as: :services
  post "assistant/messages", to: "assistant_messages#create", as: :assistant_messages
  post "assistant/actions/confirm", to: "assistant_messages#confirm", as: :confirm_assistant_action
  resources :members, only: %i[new create]
  resource :member, only: %i[edit update]
  resources :reminders, only: %i[new create update]
  resources :service_requests, only: %i[new create update]
  get "trusted-circle", to: "trusted_circle#index", as: :trusted_circle
  post "trusted-circle/contacts", to: "trusted_circle#create", as: :trusted_circle_contacts
  delete "trusted-circle/contacts/:id", to: "trusted_circle#destroy", as: :trusted_circle_contact

  namespace :api do
    namespace :v1 do
      post "auth/request-code", to: "authentication#request_code"
      post "auth/sign-in", to: "authentication#sign_in"
      post "auth/sign-up", to: "authentication#sign_up"
      post "auth/refresh", to: "authentication#refresh"
      post "care-agent/messages", to: "care_agent#message"
      post "care-agent/actions/confirm", to: "care_agent#confirm"
      resource :dashboard, only: :show
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
