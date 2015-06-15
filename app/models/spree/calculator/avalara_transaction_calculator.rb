module Spree
  class Calculator::AvalaraTransactionCalculator < Calculator::DefaultTax
    def self.description
      Spree.t(:avalara_transaction)
    end

    def compute_order(order)
      binding.pry
      raise 'Spree::AvalaraTransaction is designed to calculate taxes at the shipment and line-item levels.'
    end

    def compute_shipment_or_line_item(item)
      if rate.included_in_price
        raise 'AvalaraTransaction cannot calculate inclusive sales taxes.'
      else
        binding.pry
        # round_to_two_places(tax_for_item(item))
        0
        # TODO take discounted_amount into account. This is a problem because TaxCloud API does not take discounts nor does it return percentage rates.
      end
    end

    alias_method :compute_shipment, :compute_shipment_or_line_item
    alias_method :compute_line_item, :compute_shipment_or_line_item

    def compute_shipping_rate(shipping_rate)
      if rate.included_in_price
        raise 'AvalaraTransaction cannot calculate inclusive sales taxes.'
      else
        return 0
      end
    end

    private


  end
end
