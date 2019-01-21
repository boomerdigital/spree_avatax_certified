class CreateSpreeAvalaraTransactions < SpreeExtension::Migration[4.2]
  def change
    create_table :spree_avalara_transactions do |t|
      t.references :order
      t.references :reimbursement
      t.string :message

      t.timestamps
    end
    add_index :spree_avalara_transactions, :order_id
    add_index :spree_avalara_transactions, :reimbursement_id
  end
end
