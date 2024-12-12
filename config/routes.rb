Rails.application.routes.draw do
  get 'permission_sets/edit'
  get 'permission_sets/update'
  resources :availability_schedules
  resources :availabilities
  resources :games, only: [:index, :show]
  resources :schedules
  resources :group_availabilities, only: [:index]
  resources :proposal_availabilities, only: [:index]
  resource :user_availability
  resolve("UserAvailability") { [:user_availability] }
  resources :game_proposals, only: [:index]
  resources :game_sessions, only: [:index]
  get "calendars", to: "calendars#show"
  get "calendars/new", to: "calendars#new"
  resources :users
  shallow do
    resources :groups do
      resources :schedules
      resources :group_memberships
      resources :invites
      resources :group_availabilities
      resources :game_proposals do
        resources :game_sessions do
          resources :game_session_attendances
        end
        resources :proposal_availabilities
        resources :proposal_votes
      end
    end
  end
  get "invites/join/:invite_token", to: "group_memberships#new", as: :accept_invite
  get "groups/:group_id/permission_set/edit", to: "permission_sets#edit", as: :edit_group_permission_set
  match "groups/:group_id/permission_set", to: "permission_sets#update", via: [:patch, :put, :post], as: :group_permission_set
  get "game_proposals/:game_proposal_id/permission_set/edit", to: "permission_sets#edit", as: :edit_game_proposal_permission_set
  match "game_proposals/:game_proposal_id/permission_set", to: "permission_sets#update", via: [:patch, :put, :post], as: :game_proposal_permission_set
  namespace :two_factor_authentication do
    namespace :challenge do
      resource :totp,           only: [:new, :create]
      resource :recovery_codes, only: [:new, :create]
    end
    namespace :profile do
      resource  :totp,           only: [:new, :create, :update]
      resources :recovery_codes, only: [:index, :create]
    end
  end
  get  "/auth/failure",            to: "sessions/omniauth#failure"
  get  "/auth/:provider/callback", to: "sessions/omniauth#create"
  post "/auth/:provider/callback", to: "sessions/omniauth#create"
  get  "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new", as: :sign_up
  post "sign_up", to: "registrations#create"
  get "sign_out", to: "sessions#destroy", as: :sign_out
  get "settings", to: "users#edit", as: :settings
  get "home", to: "home#index", as: :home
  resources :sessions, only: [:index, :show, :destroy]
  resource  :password, only: [:edit, :update]
  namespace :identity do
    resource :email,              only: [:edit, :update]
    resource :email_verification, only: [:show, :create]
    resource :password_reset,     only: [:new, :edit, :create, :update]
  end
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
