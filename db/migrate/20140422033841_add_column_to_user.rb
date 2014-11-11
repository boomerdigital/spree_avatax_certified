class AddColumnToUser < ActiveRecord::Migration
  def change
    add_reference :spree_users, :spree_avalara_use_code_item, index: true
  end
end
