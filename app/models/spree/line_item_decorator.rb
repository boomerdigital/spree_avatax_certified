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
    key = "Spree::LineItem "
    key << "#{self.id}: "
    key << "#{self.quantity}x"
    key << "<#{variant.cache_key}>"
    key << "@#{self.price}#{self.currency}"
    if order.ship_address
      key << "to<#{self.order.ship_address.try(:cache_key)}>"
    elsif order.billing_address
      key << "billed_to<#{self.order.billing_address.try(:cache_key)}>"
    end
  end
end