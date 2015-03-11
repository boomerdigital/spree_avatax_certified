Spree::OrderUpdater.class_eval do

  def recalculate_adjustments
    all_adjustments.includes(:adjustable).map(&:adjustable).uniq.each do |adjustable|
      Spree::Adjustable::AdjustmentsUpdater.update(adjustable)
    end
    self.order.line_items.each do |line_item|
      store_pre_tax_amount(line_item)
    end
  end

  def store_pre_tax_amount(item)
    unless item.is_a? Spree::Order
      pre_tax_amount = case item
      when Spree::LineItem then item.discounted_amount
      when Spree::Shipment then item.discounted_cost
      end
      item.update_column(:pre_tax_amount, pre_tax_amount)
    end
  end
end