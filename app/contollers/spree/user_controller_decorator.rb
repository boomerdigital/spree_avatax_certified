Spree::Admin::UsersController.class_eval do
#Spree::User.class_eval do
  def user_params
    params.require(:user).permit(permitted_user_attributes)
    params.require(:user).permit(:customer_code, :use_code, :exemption_number)
  end
end