Rails.application.routes.draw do
  namespace :api do

      # Users
      post 'users/login' => 'users#login'
      post 'users/reset_password' => 'users#reset_password'
      post 'users/register_device_token' => 'users#register_device_token'
      resources :users, only: [:show, :create, :update]

      # Widgets
      post 'widgets/query' => 'widgets#query'
      resources :widgets

  end
end
