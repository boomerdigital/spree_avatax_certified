module Spree
  class Calculator::AvalaraTransactionCalculator < Calculator::DefaultTax
    def self.description
      Spree.t(:avalara_transaction_calculator)
    end

    def compute_order(order)
      raise 'AvalaraTransaction cannot calculate taxes at order level.'
    end

    def compute_shipment_or_line_item(item)
      order = item.order
      item_address = order.ship_address || order.billing_address
      prev_tax_amount = prev_tax_amount(item)

      return prev_tax_amount unless Spree::Config.avatax_tax_calculation
      return prev_tax_amount if %w(address cart).include?(order.state)
      return prev_tax_amount if item_address.nil?
      return prev_tax_amount unless calculable.zone.include?(item_address)

      avalara_response = get_avalara_response(order)
      tax_for_item(item, avalara_response)
    end

    alias_method :compute_shipment, :compute_shipment_or_line_item
    alias_method :compute_line_item, :compute_shipment_or_line_item

    def compute_shipping_rate(shipping_rate)
      return 0
    end

    private

    def prev_tax_amount(item)
      if rate.included_in_price
        item.included_tax_total
      else
        item.additional_tax_total
      end
    end

    def get_avalara_response(order)
      Rails.cache.fetch(cache_key(order), time_to_idle: 5.minutes) do
        order.avalara_capture
      end
    end

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

    alias_method :cache_key_without_short_hash, :cache_key
    alias_method :cache_key, :cache_key_with_short_hash

    def retrieve_rates_from_cache(order)
      Rails.cache.fetch(cache_key(order)) do
        # this is the fallback value written to the cache if there is no value
        order.avalara_capture
      end
    end

    def tax_for_item(item, avalara_response)
      prev_tax_amount = prev_tax_amount(item)

      return prev_tax_amount if avalara_response.nil?
      return prev_tax_amount if avalara_response['totalTax'] == 0.0

      avalara_response['TaxLines'].each do |line|
        if line['LineNo'] == "#{item.id}-#{item.avatax_line_code}"
          return line['TaxCalculated'].to_f
        end
      end
      0
    end
  end
end
