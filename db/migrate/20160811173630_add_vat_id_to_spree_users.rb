class AddVatIdToSpreeUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :vat_id, :string
  end
end
