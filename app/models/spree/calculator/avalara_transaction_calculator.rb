module Spree
  class Calculator::AvalaraTransactionCalculator < Calculator::DefaultTax
    def self.description
      Spree.t(:avalara_transaction)
    end

    def compute_order(order)
      raise 'Spree::AvalaraTransaction is designed to calculate taxes at the shipment and line-item levels.'
    end

    def compute_shipment_or_line_item(item)
      if rate.included_in_price
        raise 'AvalaraTransaction cannot calculate inclusive sales taxes.'
      else
        avalara_response = retrieve_rates_from_cache(item.order)

        tax_for_item(item, avalara_response)
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


    def cache_key(order)
      key = "Spree::Order #{order.number} "
      key << (order.ship_address.try(:cache_key) || order.bill_address.try(:cache_key)).to_s
      order.line_items.each do |line_item|
        key << line_item.avatax_cache_key
      end
      order.shipments.each do |shipment|
        key << shipment.avatax_cache_key
      end
      key
    end


    def retrieve_rates_from_cache(order)
      Rails.cache.fetch(cache_key(order), time_to_idle: 5.minutes) do
        order.avalara_capture
      end
    end

    def tax_for_item(item, avalara_response)
      order = item.order
      item_address = order.ship_address || order.billing_address
      if item_address.nil?
        # We can't calculate tax when we don't have a destination address
        return 0
      elsif !self.calculable.zone.include?(item_address)
        # If the order is outside our jurisdiction, then return 0
        return 0
      end

      begin
        avalara_response["TaxLines"].each do |line|
          if line["LineNo"].include?("#{item.id}-FR")
            return line["TaxCalculated"].to_f
          elsif line["LineNo"].include?(item.id.to_s)
            return line["TaxCalculated"].to_f
          end
          0
        end
      rescue => e
        raise e.message
      end
    end
  end
end
