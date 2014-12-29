Spree::Admin::UsersController.class_eval do
  def user_params
    params.require(:user).permit(permitted_user_attributes)
    params.require(:user).permit(:exemption_number, :avalara_entity_use_code_id)
  end

  def update
    if params[:user]
      roles = params[:user].delete("spree_role_ids")
    end

    if @user.update_attributes(user_params)
      if roles
        @user.spree_roles = roles.reject(&:blank?).collect{|r| Spree::Role.find(r)}
      end
      flash.now[:success] = Spree.t(:account_updated)
    end

    render :edit
  end
end
