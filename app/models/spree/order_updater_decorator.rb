Spree::OrderUpdater.class_eval do

  def recalculate_adjustments
    all_adjustments.not_avalara_tax.includes(:adjustable).map(&:adjustable).uniq.each { |adjustable| Spree::ItemAdjustments.new(adjustable).update }
  end

end