# frozen_string_literal: true

Dbwatcher::Engine.routes.draw do
  root to: "dashboard#index"

  resources :sessions do
    collection do
      delete :destroy_all
    end
  end

  resources :tables, only: %i[index show] do
    member do
      get :changes
    end
  end

  resources :queries, only: [:index] do
    collection do
      get :filter
    end
  end
end
