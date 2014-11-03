# This migration comes from spree_avatax (originally 20140418144937)
class AddTaxUseCodeToShippingMethods < ActiveRecord::Migration
  def change
    add_column :spree_shipping_methods, :tax_use_code, :string
  end
end
