class AddColumnToUser < ActiveRecord::Migration
  def change
    add_column :spree_users, :avalara_entity_use_code_id, :integer
  end
end
