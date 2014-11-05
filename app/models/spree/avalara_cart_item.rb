require 'builder'

module Spree
  class AvalaraCartItem < ActiveRecord::Base
    belongs_to :line_item, class_name: 'Spree::LineItem'
    belongs_to :avalara_transaction, class_name: 'Spree::AvalaraTransaction'

    validates :index, :tic, :sku, :price, :quantity, presence: true

    accepts_nested_attributes_for :line_item

    def to_hash
      {
        'Index' => index,
        'TIC' => tic,
        'ItemID' => sku,
        'Price' => price.to_s,
        'Qty' => quantity,
        'TaxCategory' => tax_category
      }
    end
  end
end
