# This migration comes from spree_avatax (originally 20130103032528)
class CreateSpreeAvalaraCartItems < ActiveRecord::Migration
  def change
    create_table :spree_avalara_cart_items do |t|
      t.integer :index
      t.integer :tax_code
      t.string  :sku
      t.integer :quantity
      t.decimal :price, :precision => 8, :scale => 5, :default => 0
      t.decimal :amount, :precision => 8, :scale => 5, :default => 0
      t.decimal :ship_total, :precision => 8, :scale => 5, :default => 0
      t.references :line_item
      t.references :avalara_transaction
      t.string :type

      t.timestamps
    end
    add_index :spree_avalara_cart_items, :line_item_id
    add_index :spree_avalara_cart_items, :avalara_transaction_id
  end
end
