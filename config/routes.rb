Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :avatax_settings  do
      get :ping_my_service, :get_file_content_txt_svc, :get_file_content_post_avatax, :get_file_content_avatax_ord

    end

  end
 # get '/admin/log/tax_svc', :to => send_file('/log/tax_svc.txt')
#redirect('../log/tax_svc.txt')


end
