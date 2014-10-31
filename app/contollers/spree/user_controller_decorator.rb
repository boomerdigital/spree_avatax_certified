Spree::Admin::UsersController.class_eval do
  def user_params
    params.require(:user).permit(permitted_user_attributes)
    params.require(:user).permit(:customer_code, :use_code, :exemption_number, :spree_avalara_use_code_item_id)
  end
end
