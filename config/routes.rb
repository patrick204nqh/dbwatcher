# frozen_string_literal: true

Dbwatcher::Engine.routes.draw do
  root to: "dashboard#index"

  # Dashboard clear all action
  delete :clear_all, to: "dashboard#clear_all"

  resources :sessions do
    member do
      get :changes
      get :summary
      get :diagrams
    end

    collection do
      delete :clear
    end
  end

  # API namespace for JSON-only endpoints
  namespace :api do
    namespace :v1 do
      resources :sessions, only: [] do
        member do
          get :changes_data
          get :summary_data
          get :diagram_data
        end

        collection do
          get :diagram_types
        end
      end
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
