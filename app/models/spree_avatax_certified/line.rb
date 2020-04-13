module SpreeAvataxCertified
  class Line
    attr_reader :order, :lines

    def initialize(order, invoice_type, refund = nil)
      @order = order
      @invoice_type = invoice_type
      @lines = []
      @refund = refund
      @refunds = []
      build_lines
    end

    def build_lines
      if %w(ReturnInvoice ReturnOrder).include?(@invoice_type)
        refund_lines
      else
        item_lines_array
        shipment_lines_array
      end
    end

    def item_line(line_item)
      {
        number: "#{line_item.id}-LI",
        description: line_item.name[0..255],
        taxCode: line_item.tax_category.try(:tax_code) || '',
        itemCode: truncateLine(line_item.variant.sku),
        quantity: line_item.quantity,
        amount: line_item.amount.to_f,
        discounted: discounted?(line_item),
        taxIncluded: tax_included_in_price?(line_item),
        addresses: {
          shipFrom: get_stock_location(line_item),
          shipTo: ship_to
        }
      }.merge(base_line_hash)
    end

    def item_lines_array
      order.line_items.each do |line_item|
        lines << item_line(line_item)
      end
    end

    def shipment_lines_array
      order.shipments.each do |shipment|
        next unless shipment.tax_category

        lines << shipment_line(shipment)
      end
    end

    def shipment_line(shipment)
      {
        number: "#{shipment.id}-FR",
        itemCode: truncateLine(shipment.shipping_method.name),
        quantity: 1,
        amount: shipment.discounted_amount.to_f,
        description: 'Shipping Charge',
        taxCode: shipment.shipping_method_tax_code,
        discounted: !shipment.promo_total.zero?,
        taxIncluded: tax_included_in_price?(shipment),
        addresses: {
          shipFrom: shipment.stock_location.to_avatax_hash,
          shipTo: ship_to
        }
      }.merge(base_line_hash)
    end

    def refund_lines
      return lines << refund_line if @refund.reimbursement.nil?

      return_items = @refund.reimbursement.customer_return.return_items
      inventory_units = Spree::InventoryUnit.where(id: return_items.pluck(:inventory_unit_id))

      inventory_units.group_by(&:line_item_id).each_value do |inv_unit|

        inv_unit_ids = inv_unit.map(&:id)
        return_items = Spree::ReturnItem.where(inventory_unit_id: inv_unit_ids)
        quantity = inv_unit.uniq.count
        amount = return_items.sum(:pre_tax_amount)

        lines << return_item_line(inv_unit.first.line_item, quantity, amount)
      end
    end

    def refund_line
      {
        number: "#{@refund.id}-RA",
        itemCode: truncateLine(@refund.transaction_id) || 'Refund',
        quantity: 1,
        amount: -@refund.amount.to_f,
        description: 'Refund',
        taxIncluded: true,
        addresses: {
          shipFrom: default_ship_from,
          shipTo: ship_to
        }
      }.merge(base_line_hash)
    end

    def return_item_line(line_item, quantity, amount)
      {
        number: "#{line_item.id}-LI",
        description: line_item.name[0..255],
        taxCode: line_item.tax_category.try(:tax_code) || '',
        itemCode: truncateLine(line_item.variant.sku),
        quantity: quantity,
        amount: -amount.to_f,
        addresses: {
          shipFrom: get_stock_location(line_item),
          shipTo: ship_to
        }
      }.merge(base_line_hash)
    end

    def get_stock_location(li)
      inventory_units = li.inventory_units

      return default_ship_from if inventory_units.blank?

      stock_loc = inventory_units.first.try(:shipment).try(:stock_location)

      stock_loc.nil? ? {} : stock_loc.to_avatax_hash
    end

    def ship_to
      order.ship_address.to_avatax_hash
    end

    def default_ship_from
      ::Spree::StockLocation.order_default.first.to_avatax_hash
    end

    def truncateLine(line)
      return if line.nil?

      line.truncate(50)
    end

    private

    def base_line_hash
      @base_line_hash ||= {
        customerUsageType: order.customer_usage_type,
        businessIdentificationNo: business_id_no,
        exemptionCode: order.user.try(:exemption_number)
      }
    end

    def business_id_no
      order.user.try(:vat_id)
    end

    def discounted?(line_item)
      line_item.adjustments.promotion.eligible.any? || order.adjustments.promotion.eligible.any?
    end

    def tax_included_in_price?(item)
      if item.tax_category.present?
        order.tax_zone.tax_rates.where(tax_category: item.tax_category).try(:first).try(:included_in_price)
      else
        order.tax_zone.tax_rates.try(:first).try(:included_in_price)
      end
    end
  end
end
