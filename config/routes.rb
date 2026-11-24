Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :places, only: [:index, :show] do
    resources :visits, only: [:create]
  end

  resources :visits, only: [:show, update] do
    resources :messages, only: [:create]
    member do
      get :review
    end
  end

end
