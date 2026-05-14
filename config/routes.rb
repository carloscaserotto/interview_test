Rails.application.routes.draw do

  resources :books do
    member do
      post 'reserve'
    end
  end
end
