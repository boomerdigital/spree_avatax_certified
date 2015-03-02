
Spree::ItemAdjustments.class_eval do

  def update_adjustments
    promo_total = 0
    run_callbacks :promo_adjustments do
      promotion_total = adjustments.promotion.reload.map do |adjustment|
        adjustment.update!(@item)
      end.compact.sum

      unless promotion_total == 0
        choose_best_promotion_adjustment
      end
      promo_total = best_promotion_adjustment.try(:amount).to_f
    end

    included_tax_total = 0
    additional_tax_total = 0
    run_callbacks :tax_adjustments do
      tax = (item.respond_to?(:all_adjustments) ? item.all_adjustments : item.adjustments).tax
      included_tax_total = tax.where(included: true).reload.map(&:update!).compact.sum
      additional_tax_total = tax.additional.reload.map(&:update!).compact.sum
    end

    avalara_tax = (item.respond_to?(:all_adjustments) ? item.all_adjustments : item.adjustments).avalara_tax

    item.update_columns(
      :promo_total => promo_total,
      :included_tax_total => included_tax_total,
      :updated_at => Time.now,
      )

    unless item.is_a? Spree::Order
      case item
      when Spree::LineItem
        item_amount = item.discounted_amount
        item.update_columns(
          :additional_tax_total => additional_tax_total + avalara_tax.sum(:amount),
          :adjustment_total => promo_total + additional_tax_total)
      when Spree::Shipment
        item_amount = item.discounted_cost
        item.update_columns(
          :additional_tax_total => additional_tax_total,
          :adjustment_total => promo_total + additional_tax_total + avalara_tax.sum(:amount))
      end
      pre_tax_amount = item_amount
      item.update_columns(pre_tax_amount: pre_tax_amount)
    end
  end

end