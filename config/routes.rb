# frozen_string_literal: true

Dbwatcher::Engine.routes.draw do
  resources :sessions, only: %i[index show] do
    collection do
      delete :destroy_all
    end
  end
  root to: "sessions#index"
end
