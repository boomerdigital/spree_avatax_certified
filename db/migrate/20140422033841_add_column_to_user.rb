class AddColumnToUser < ActiveRecord::Migration
  def change
    add_column :spree_users, :spree_avalara_use_code_item_id, :integer
  end
end
