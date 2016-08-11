Spree::Admin::UsersController.class_eval do
  def avalara_information
    if request.put?
      if @user.update_attributes(user_params)
        flash.now[:success] = Spree.t(:account_updated)
      end
    end

    render :avalara_information
  end
end
