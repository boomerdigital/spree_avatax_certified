Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :avatax_settings do
      get :ping_my_service, :get_file_txt_tax_svc, :get_file_post_order_to_avalara, :get_file_avalara_order, :erase_tax_svc_data, :erase_post_order_to_avalara_data, :erase_avalara_order_data
    end
    resources :avalara_entity_use_codes do

    end
  end
end
