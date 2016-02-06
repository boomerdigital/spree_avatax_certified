module SpreeAvataxCertified
  class Line
    attr_reader :order, :invoice_type, :lines

    def initialize(order, invoice_type, refund = nil)
      @logger ||= AvataxHelper::AvataxLog.new('avalara_order_lines', 'SpreeAvataxCertified::Line', "Building Lines for Order#: #{order.number}")
      @order = order
      @invoice_type = invoice_type
      @lines = []
      @refund = refund
      @refunds = []
      @stock_locations = order_stock_locations
      build_lines
      @logger.debug @lines
    end

    def build_lines
      if %w(ReturnInvoice ReturnOrder).include?(invoice_type)
        refund_lines
      else
        item_lines_array
        shipment_lines_array
      end
    end

    def item_line(line_item)
      stock_location = get_stock_location(line_item)

      {
        LineNo: "#{line_item.id}-LI",
        Description: line_item.name[0..255],
        TaxCode: line_item.tax_category.try(:tax_code) || 'P0000000',
        ItemCode: line_item.variant.sku,
        Qty: line_item.quantity,
        Amount: line_item.discounted_amount.to_f,
        OriginCode: stock_location,
        DestinationCode: 'Dest',
        CustomerUsageType: customer_usage_type,
        Discounted: true
      }
    end

    def item_lines_array
      line_item_lines = []

      order.line_items.each do |line_item|
        line_item_lines << item_line(line_item)
      end

      lines.concat(line_item_lines) unless line_item_lines.empty?
      line_item_lines
    end

    def shipment_lines_array
      ship_lines = []
      order.shipments.each do |shipment|
        next unless shipment.tax_category
        ship_lines << shipment_line(shipment)
      end

      lines.concat(ship_lines) unless ship_lines.empty?
      ship_lines
    end

    def shipment_line(shipment)
      {
        LineNo: "#{shipment.id}-FR",
        ItemCode: shipment.shipping_method.name,
        Qty: 1,
        Amount: shipment.discounted_amount.to_f,
        OriginCode: "#{shipment.stock_location_id}",
        DestinationCode: 'Dest',
        CustomerUsageType: customer_usage_type,
        Description: 'Shipping Charge',
        TaxCode: shipment.shipping_method.tax_category.try(:tax_code) || 'FR000000',
        Discounted: false
      }
    end

    def refund_lines
      return @refunds << refund_line if @refund.reimbursement.nil?

      return_items = @refund.reimbursement.customer_return.return_items
      li_ids = Spree::InventoryUnit.where(id: return_items.pluck(:inventory_unit_id)).select(:line_item_id)
      amount = return_items.sum(:pre_tax_amount) / li_ids.uniq.count

      return_items.map(&:inventory_unit).group_by(&:line_item_id).each_value do |inv_unit|
        quantity = inv_unit.uniq.count
        @refunds << return_item_line(inv_unit.first.line_item, quantity, amount)
      end

      lines.concat(@refunds) unless @refunds.empty?
      @refunds
    end

    def refund_line
      {
        LineNo: "#{@refund.id}-RA",
        ItemCode: @refund.transaction_id || 'Refund',
        Qty: 1,
        Amount: -@refund.amount.to_f,
        OriginCode: 'Orig',
        DestinationCode: 'Dest',
        CustomerUsageType: customer_usage_type,
        Description: 'Refund'
      }
    end

    def return_item_line(line_item, quantity, amount)
      stock_location = get_stock_location(line_item)

      line = {
        LineNo: "#{line_item.id}-LI",
        Description: line_item.name[0..255],
        TaxCode: line_item.tax_category.try(:tax_code) || 'P0000000',
        ItemCode: line_item.variant.sku,
        Qty: quantity,
        Amount: -amount.to_f,
        OriginCode: stock_location,
        DestinationCode: 'Dest',
        CustomerUsageType: customer_usage_type
      }

      line
    end

    def order_stock_locations
      stock_location_ids = Spree::Stock::Coordinator.new(order).packages.map(&:to_shipment).map(&:stock_location_id)
      Spree::StockLocation.where(id: stock_location_ids)
    end

    def get_stock_location(line_item)
      line_item_stock_locations = @stock_locations.joins(:stock_items).where(spree_stock_items: { variant_id: line_item.variant_id })

      if line_item_stock_locations.empty?
        'Orig'
      else
        "#{line_item_stock_locations.first.id}"
      end
    end

    def customer_usage_type
      order.user ? order.user.avalara_entity_use_code.try(:use_code) : ''
    end
  end
end
