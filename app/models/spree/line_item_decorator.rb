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

  def update_avalara_tax
    tax = self.adjustments.avalara_tax.sum(:amount)
    self.update(adjustment_total: tax)
  end
end