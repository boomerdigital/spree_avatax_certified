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
        LineNo: "#{line_item.id}-LI",
        Description: line_item.name[0..255],
        TaxCode: line_item.tax_category.try(:tax_code) || 'P0000000',
        ItemCode: line_item.variant.sku,
        Qty: line_item.quantity,
        Amount: line_item.amount.to_f,
        OriginCode: get_stock_location(line_item),
        DestinationCode: 'Dest',
        CustomerUsageType: order.customer_usage_type,
        Discounted: discounted?(line_item),
        TaxIncluded: tax_included_in_price?(line_item)
      }
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
        LineNo: "#{shipment.id}-FR",
        ItemCode: shipment.shipping_method.name,
        Qty: 1,
        Amount: shipment.discounted_amount.to_f,
        OriginCode: "#{shipment.stock_location_id}",
        DestinationCode: 'Dest',
        CustomerUsageType: order.customer_usage_type,
        Description: 'Shipping Charge',
        TaxCode: shipment.shipping_method_tax_code,
        Discounted: false,
        TaxIncluded: tax_included_in_price?(shipment)
      }
    end

    def refund_lines
      return lines << refund_line if @refund.reimbursement.nil?

      return_items = @refund.reimbursement.customer_return.return_items
      inventory_units = Spree::InventoryUnit.where(id: return_items.pluck(:inventory_unit_id))

      inventory_units.group_by(&:line_item_id).each_value do |inv_unit|

        inv_unit_ids = inv_unit.map { |iu| iu.id }
        return_items = Spree::ReturnItem.where(inventory_unit_id: inv_unit_ids)
        quantity = inv_unit.uniq.count
        amount = return_items.sum(:pre_tax_amount)

        lines << return_item_line(inv_unit.first.line_item, quantity, amount)
      end
    end

    def refund_line
      {
        LineNo: "#{@refund.id}-RA",
        ItemCode: @refund.transaction_id || 'Refund',
        Qty: 1,
        Amount: -@refund.amount.to_f,
        OriginCode: 'Orig',
        DestinationCode: 'Dest',
        CustomerUsageType: order.customer_usage_type,
        Description: 'Refund',
        TaxIncluded: true
      }
    end

    def return_item_line(line_item, quantity, amount)
      {
        LineNo: "#{line_item.id}-LI",
        Description: line_item.name[0..255],
        TaxCode: line_item.tax_category.try(:tax_code) || 'P0000000',
        ItemCode: line_item.variant.sku,
        Qty: quantity,
        Amount: -amount.to_f,
        OriginCode: get_stock_location(line_item),
        DestinationCode: 'Dest',
        CustomerUsageType: order.customer_usage_type
      }
    end

    def get_stock_location(li)
      inventory_units = li.inventory_units

      return 'Orig' if inventory_units.blank?

      # What if inventory units have different stock locations?
      stock_loc_id = inventory_units.first.try(:shipment).try(:stock_location_id)

      stock_loc_id.nil? ? 'Orig' : "#{stock_loc_id}"
    end

    private

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
