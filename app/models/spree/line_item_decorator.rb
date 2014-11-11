Spree::LineItem.class_eval do
  # belongs_to :avalara_transaction, class_name: 'Spree::AvalaraTransaction'

  def to_hash
    {
      'Index' => id,
      'Name' => name,
      'ItemID' => sku,
      'Price' => price.to_s,
      'Qty' => quantity,
      'TaxCategory' => tax_category
    }
  end
end