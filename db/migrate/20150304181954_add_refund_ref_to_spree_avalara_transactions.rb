class AddRefundRefToSpreeAvalaraTransactions < ActiveRecord::Migration
  def change
    add_reference :spree_avalara_transactions, :refund, index: true
  end
end
