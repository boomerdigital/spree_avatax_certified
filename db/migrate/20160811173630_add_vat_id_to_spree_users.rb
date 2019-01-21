class AddVatIdToSpreeUsers < SpreeExtension::Migration[4.2]
  def change
    add_column :spree_users, :vat_id, :string
  end
end
