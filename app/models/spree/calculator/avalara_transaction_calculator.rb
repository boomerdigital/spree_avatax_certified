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
        @avalara_transaction ||= item.order.avalara_transaction

        if @avalara_response.nil?
          @avalara_response ||= item.order.avalara_capture
        end

        item.order.rtn_tax["TaxLines"].each do |line|
          if line["LineNo"].include?(item.id.to_s)
            return line["TaxCalculated"].to_f
          end
           0
        end
      end
    end

    alias_method :compute_shipment, :compute_shipment_or_line_item
    alias_method :compute_line_item, :compute_shipment_or_line_item

    def compute_shipping_rate(shipping_rate)
        binding.pry
      if rate.included_in_price
        raise 'AvalaraTransaction cannot calculate inclusive sales taxes.'
      else
        return 0
      end
    end

    private


  end
end
