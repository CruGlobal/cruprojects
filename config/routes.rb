Github::Application.routes.draw do
  get 'encouragement', to: 'encouragement#index'

  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)

  resources :teams
  resources :off_days

  resources :team_members do
    member do
      get :rescue
    end
  end

  resources :repos do
    collection do
      get :details
    end
  end
  root "repos#index"

  get '/auth/:provider/callback', to: 'sessions#create'
end
