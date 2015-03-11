Spree::Adjustable::AdjustmentsUpdater.class_eval do
  def update_tax_adjustments
    tax = (adjustable.try(:all_adjustments) || adjustable.adjustments).all_tax
    @included_tax_total = tax.is_included.reload.map(&:update!).compact.sum
    @additional_tax_total = tax.additional.reload.map(&:update!).compact.sum
  end
end