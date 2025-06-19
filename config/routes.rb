# frozen_string_literal: true

Dbwatcher::Engine.routes.draw do
  root to: "dashboard#index"

  # Dashboard clear all action
  delete :clear_all, to: "dashboard#clear_all"

  resources :sessions do
    member do
      get :diagram
      get :summary
    end

    collection do
      delete :clear
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
      delete :clear
    end
  end
end
