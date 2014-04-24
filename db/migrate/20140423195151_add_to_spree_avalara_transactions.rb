class AddToSpreeAvalaraTransactions < ActiveRecord::Migration
  def change
    add_column :spree_avalara_transactions, :return_authorization_id, :integer
  end
end
