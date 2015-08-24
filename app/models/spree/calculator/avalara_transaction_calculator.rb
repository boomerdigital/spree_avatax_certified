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

        if item.order.state == 'complete'
          avalara_response = item.order.avalara_capture
        else
          avalara_response = retrieve_rates_from_cache(item.order)
        end

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
      key = order.avatax_cache_key
      key << (order.ship_address.try(:cache_key) || order.bill_address.try(:cache_key)).to_s
      order.line_items.each do |line_item|
        key << line_item.avatax_cache_key
      end
      order.shipments.each do |shipment|
        key << shipment.avatax_cache_key
      end
      order.all_adjustments.not_tax do |adj|
        key << adj.avatax_cache_key
      end
      key
    end

    # long keys blow up in dev with the default ActiveSupport::Cache::FileStore
    # This transparently shrinks 'em
    def cache_key_with_short_hash(order)
      long_key   = cache_key_without_short_hash(order)
      short_key  = Digest::SHA1.hexdigest(long_key)
      "avtx_#{short_key}"
    end

    alias_method_chain :cache_key, :short_hash

    def retrieve_rates_from_cache(order)
      Rails.cache.fetch(cache_key(order), time_to_idle: 5.minutes) do
        # this is the fallback value written to the cache if there is no value
        order.avalara_capture
      end
    end

    def tax_for_item(item, avalara_response)
      order = item.order
      item_address = order.ship_address || order.billing_address

      return 0 if order.state == %w(address cart)
      return 0 if item_address.nil?
      return 0 if !self.calculable.zone.include?(item_address)

      avalara_response['TaxLines'].each do |line|
        if line['LineNo'] == "#{item.id}-#{item.avatax_line_code}"
          return line['TaxCalculated'].to_f
        end
      end
      0
    end
  end
end
