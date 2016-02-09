module SpreeAvataxCertified
  class Line
    attr_reader :order, :invoice_type, :lines

    def initialize(order, invoice_type, return_authorization=nil)
      @logger ||= AvataxHelper::AvataxLog.new('avalara_order_lines', 'SpreeAvataxCertified::Line', "Building Lines for Order#: #{order.number}")
      @order = order
      @invoice_type = invoice_type
      @lines = []
      @return_authorization = return_authorization
      @stock_locations = order_stock_locations
      build_lines
      @logger.debug @lines
    end

    def build_lines
      if %w(ReturnInvoice ReturnOrder).include?(invoice_type)
        return_authorization_lines
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
        TaxCode: line_item.tax_category.try(:description) || 'P0000000',
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
        TaxCode: shipment.shipping_method_tax_code,
        Discounted: false
      }
    end

    def return_authorization_lines
      @logger.info('build return return_authorization lines')

      return_auth_lines = []

      order.return_authorizations.each do |return_auth|
        next if return_auth != return_authorization
        amount = return_auth.amount / return_auth.inventory_units.select(:line_item_id).uniq.count
        return_auth.inventory_units.group_by(&:line_item_id).each_value do |inv_unit|
          quantity = inv_unit.uniq.count
          return_auth_lines << return_item_line(inv_unit.first.line_item, quantity, amount)
        end
      end

      @logger.info_and_debug('return_authorization_lines', return_auth_lines)
      lines.concat(return_auth_lines) unless return_auth_lines.empty?
      return_auth_lines
    end

    def return_item_line(line_item, quantity, amount)
      @logger.info("build return_line_item line: #{line_item.name}")

      stock_location = get_stock_location(@stock_locations, line_item)

      line = {
        LineNo: "#{line_item.id}-LI",
        Description: line_item.name[0..255],
        TaxCode: line_item.tax_category.try(:description) || 'P0000000',
        ItemCode: line_item.variant.sku,
        Qty: quantity,
        Amount: -amount.to_f,
        OriginCode: stock_location,
        DestinationCode: 'Dest',
        CustomerUsageType: customer_usage_type
      }

      @logger.debug line

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
