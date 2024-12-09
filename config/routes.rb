Rails.application.routes.draw do
  # Define the root path as the books index page
  root "books#index"

  get 'covers/*path', to: 'covers#show', as: 'cover_image'

  resources :books, only: [:index] do
    member do
      get :download
      get :preview
    end
  end

  get 'start_library_watcher', to: 'library_watcher#start'

end
