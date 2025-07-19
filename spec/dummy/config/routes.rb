# frozen_string_literal: true

Rails.application.routes.draw do
  # DBWatcher engine will be auto-mounted at /dbwatcher by the engine itself

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Set root to testing interface for easy access
  root "testing#index"

  # Users with comprehensive actions for testing
  resources :users do
    member do
      patch :toggle_active
    end
    collection do
      patch :bulk_update
      delete :bulk_delete
      post :reset_data
    end

    # Nested posts for users
    resources :posts, except: [:index] do
      member do
        patch :publish
        patch :archive
        post :increment_views
      end

      # Nested comments for posts
      resources :comments, except: %i[index show]
    end
  end

  # Posts (global view)
  resources :posts, only: %i[index show edit update] do
    member do
      post :increment_views
    end
    resources :comments, only: %i[create update destroy]
  end

  # Tags for categorization
  resources :tags, except: [:show]

  # Roles for permissions
  resources :roles, except: [:show]

  # Simplified Testing Actions
  post :basic_operations, to: "testing#basic_operations"
  post :mass_updates, to: "testing#mass_updates"
  post :high_volume_operations, to: "testing#high_volume_operations"
  post :test_relationships, to: "testing#test_relationships"
  post :trigger_errors, to: "testing#trigger_errors"
  post :reset_data, to: "testing#reset_data"

  # Quick access routes
  get "/quick_stats", to: "testing#quick_stats"
  get "/stats", to: "application#stats"
end
