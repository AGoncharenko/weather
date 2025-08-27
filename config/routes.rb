Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :weather, only: %i[index create]
  root "weather#index"
end
