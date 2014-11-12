class AddAvataxUserToUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :exemption_number, :string
  end
end
