Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :places, only: [:index, :show] do
    resources :visits, only: [:create]
  end

  resources :visits, only: [:show, :update] do
    resources :messages, only: [:create]
    resources :phrases, only: [:create]         # "Add" on a suggested staff phrase
    resources :review_messages, only: [:create] # post-visit "what did you hear?" AI chat
    member do
      get :review
      get :phrase_suggestions # lazy-loaded into the review page
    end
  end

end
