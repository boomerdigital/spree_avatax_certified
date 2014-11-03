# This migration comes from spree_avatax (originally 20140422033841)
class AddColumnToUser < ActiveRecord::Migration
  def change
    add_column :spree_users, :spree_avalara_use_code_item_id, :integer
  end
end
