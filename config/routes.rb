Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  resources :tasks do
    member do
      patch :start
      patch :complete
      patch :interrupt
      patch :skip
    end
  end

  get "focus", to: "focus#show", as: :focus
  get "history", to: "history#index", as: :history
end
