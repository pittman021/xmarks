Rails.application.routes.draw do
  resources :checkouts, only: [:create]
  get 'checkouts/show', to: 'checkouts#show', as: 'checkouts_show'
  get "home/index"
  get 'books', to: 'books#index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  get '/logout', to: 'sessions#destroy'

    # Add this line to test:
  get '/auth/twitter', to: 'sessions#create'

  get  '/test', to: 'sessions#test'

  get '/bookmarks', to: 'bookmarks#index'

  post '/get_book_recs', to: 'books#get_book_recs'

  root 'home#index'

  resources :books

  # Defines the root path route ("/")
  # root "posts#index"
end
