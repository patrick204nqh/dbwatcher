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

  # Testing actions accessible from root path
  post :complex_transaction, to: "testing#complex_transaction"
  post :mass_updates, to: "testing#mass_updates"
  post :cascade_deletes, to: "testing#cascade_deletes"
  post :nested_operations, to: "testing#nested_operations"
  post :bulk_operations, to: "testing#bulk_operations"
  post :concurrent_updates, to: "testing#concurrent_updates"
  post :trigger_errors, to: "testing#trigger_errors"
  post :reset_data, to: "testing#reset_data"
  post :high_volume_inserts, to: "testing#high_volume_inserts"
  post :high_volume_updates, to: "testing#high_volume_updates"
  post :high_volume_deletes, to: "testing#high_volume_deletes"
  post :mixed_high_volume_operations, to: "testing#mixed_high_volume_operations"
  post :batch_processing, to: "testing#batch_processing"

  # Quick access routes for testing
  get "/quick_test", to: "testing#quick_test"
  get "/stats", to: "application#stats"
end
