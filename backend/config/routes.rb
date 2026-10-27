# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq dashboard. Development only: add authentication before exposing it elsewhere.
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?

  namespace :api do
    get "health", to: "health#show"
  end
end
