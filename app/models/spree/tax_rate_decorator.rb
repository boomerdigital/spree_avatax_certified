Spree::TaxRate.class_eval do
    def compute_amount(item)
      if included_in_price
        if default_zone_or_zone_match?(item.order.tax_zone)
          calculator.compute(item)
        else
          # In this case, it's a refund.
          calculator.compute(item) * - 1
        end
      else
        calculator.compute(item)
      end
    end
end