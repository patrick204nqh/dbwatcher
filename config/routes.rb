# frozen_string_literal: true

Dbwatcher::Engine.routes.draw do
  root to: "dashboard#index"

  # Dashboard actions
  delete :clear_all, to: "dashboard#clear_all"

  # Dashboard system info actions
  namespace :dashboard do
    resources :system_info, only: [] do
      collection do
        post :refresh
        delete :clear_cache
      end
    end
  end

  resources :sessions do
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

      # System information API routes
      resources :system_info, only: [:index] do
        collection do
          post :refresh
          get :machine
          get :database
          get :runtime
          get :summary
          delete :clear_cache
          get :cache_status
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
