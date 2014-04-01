Spree::CheckoutController.class_eval do

  #rescue_from SpreeAvatax::Error do |exception|
  #  flash[:error] = exception.message
  #  redirect_to checkout_state_path(:address)
  #end
  #
  #rescue_from Avatax::Errors::ApiError do |exception|
  #  flash[:error] = Spree.t("address_verification_failed")
  #  redirect_to checkout_state_path(:address)
  #end

end