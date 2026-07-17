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
  post "focus/start", to: "focus#start", as: :start_focus
  patch "focus/sessions/:work_session_id/extend", to: "focus#extend", as: :extend_focus
  patch "focus/sessions/:work_session_id/complete", to: "focus#complete", as: :complete_focus
  patch "focus/sessions/:work_session_id/interrupt", to: "focus#interrupt", as: :interrupt_focus
  get "history", to: "history#index", as: :history
end
