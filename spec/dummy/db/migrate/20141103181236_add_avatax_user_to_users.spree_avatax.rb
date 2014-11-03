# This migration comes from spree_avatax (originally 20140408211722)
class AddAvataxUserToUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :customer_code, :string
    add_column :spree_users, :use_code, :string
    add_column :spree_users, :exemption_number, :string
  end
end
