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

  def update_adjustments
    if quantity_changed?
      update_tax_charge # Called to ensure pre_tax_amount is updated.
      recalculate_adjustments
      update_avalara_tax
    end
  end

  def update_avalara_tax
    tax = self.adjustments.avalara_tax.sum(:amount)
    self.update(adjustment_total: tax)
  end
end