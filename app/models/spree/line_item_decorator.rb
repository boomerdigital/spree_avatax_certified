Spree::LineItem.class_eval do

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

  def avatax_cache_key
    key = ["Spree::LineItem"]
    key << self.id
    key << self.quantity
    key << self.cost_price
    key.join("-")
  end
end
