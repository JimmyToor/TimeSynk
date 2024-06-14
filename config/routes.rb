Rails.application.routes.draw do
  get 'user/edit'
  resources :game_session_attendances
  resources :group_availabilities
  resources :proposal_availabilities
  resources :user_availabilities
  resources :game_sessions
  resources :schedules
  resources :proposal_votes
  resources :game_proposals
  resources :group_memberships
  resources :groups
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
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  get "sign_out", to: "sessions#destroy", as: :sign_out
  get "settings", to: "user#edit", as: :settings
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
