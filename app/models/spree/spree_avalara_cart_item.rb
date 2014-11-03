require 'builder'
module Spree
  class SpreeAvalaraCartItem < ActiveRecord::Base

    belongs_to :line_item
    belongs_to :avalara_transaction
    validates :index, :tic, :sku, :price, :quantity, :presence => true
    accepts_nested_attributes_for :line_item

    def to_hash
      {
        'Index' => index,
        'TIC' => tic,
        'ItemID' => sku,
        'Price' => price.to_s,
        'Qty' => quantity,
        'TaxCategory' => tax_category,
      }
    end
  end
end
