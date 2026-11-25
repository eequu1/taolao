Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :places, only: [:index, :show] do
    resources :visits, only: [:create]
  end

  resources :visits, only: [:show, :update] do
    resources :messages, only: [:create]
    resources :phrases, only: [:create] # phrases heard on the visit, added after the review
    member do
      get :review
    end
  end

end
