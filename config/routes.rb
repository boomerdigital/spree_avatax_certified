Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :avatax_settings  do
      get :ping_my_service
    end

  end
end
