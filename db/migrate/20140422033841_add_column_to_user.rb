class AddColumnToUser < ActiveRecord::Migration
  def change
    add_column :spree_users, :avalara_use_code_item_id, :integer
  end
end
