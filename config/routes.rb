Github::Application.routes.draw do
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

  get 'monitors/lb' => 'monitors#lb'
end
