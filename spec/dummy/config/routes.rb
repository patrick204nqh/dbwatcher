# frozen_string_literal: true

Rails.application.routes.draw do
  # DBWatcher engine will be auto-mounted at /dbwatcher by the engine itself

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Set root to users index for easy testing
  root "users#index"

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

  # Special testing namespace for complex database operations
  namespace :testing do
    get :complex_transaction, controller: "testing"
    get :mass_updates, controller: "testing"
    get :cascade_deletes, controller: "testing"
    get :nested_operations, controller: "testing"
    get :bulk_operations, controller: "testing"
    get :concurrent_updates, controller: "testing"
    get :trigger_errors, controller: "testing"
    get :reset_data, controller: "testing"
    post :complex_transaction, controller: "testing"
    post :mass_updates, controller: "testing"
    post :cascade_deletes, controller: "testing"
    post :nested_operations, controller: "testing"
    post :bulk_operations, controller: "testing"
    post :concurrent_updates, controller: "testing"
    post :trigger_errors, controller: "testing"
    post :reset_data, controller: "testing"
  end

  # Quick access routes for testing
  get "/quick_test", to: "testing/testing#quick_test"
  get "/stats", to: "application#stats"
end
