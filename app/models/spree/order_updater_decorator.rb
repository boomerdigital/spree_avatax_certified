Spree::OrderUpdater.class_eval do
  # COPY FROM CORE
  # 
  # Updates the following Order total values:
  #
  # +payment_total+      The total value of all finalized Payments (NOTE: non-finalized Payments are excluded)
  # +item_total+         The total value of all LineItems
  # +adjustment_total+   The total value of all adjustments (promotions, credits, etc.)
  # +total+              The so-called "order total."  This is equivalent to +item_total+ plus +adjustment_total+.
  def update_totals
    order.payment_total = payments.completed.map(&:amount).sum
    order.item_total = line_items.map(&:amount).sum
    order.adjustment_total = adjustments.eligible.map(&:amount).sum

    # - replaced -
    #order.tax_total = order.all_adjustments.tax.map(&:amount).sum
    order.tax_total = order.adjustments.avalara_tax.map(&:amount).sum

    order.total = order.item_total + order.adjustment_total
  end
end
