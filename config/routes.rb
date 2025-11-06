Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root path
  root 'forecasts#index'
  
  # Forecast routes
  resources :forecasts, only: [:index, :create] do
    collection do
      get 'search'
      post 'search', to: 'forecasts#create'
    end
  end
  
  # Health check endpoint
  get 'up', to: 'rails/health#show', as: :rails_health_check
end

