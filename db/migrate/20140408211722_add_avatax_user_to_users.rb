class AddAvataxUserToUsers < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_users, :exemption_number, :string
  end
end
