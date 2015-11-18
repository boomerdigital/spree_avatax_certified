module SpreeAvataxCertified
  class Line
    attr_reader :order, :invoice_type, :lines, :stock_locations

    def initialize(order, invoice_type)
      @logger ||= AvataxHelper::AvataxLog.new('avalara_order_lines', 'SpreeAvataxCertified::Line', 'building lines')
      @order = order
      @invoice_type = invoice_type
      @lines = []
      @stock_locations = order_stock_locations
      build_lines
    end

    def build_lines
      @logger.info('build lines')

      if invoice_type == 'ReturnInvoice' || invoice_type == 'ReturnOrder'
        refund_lines
      else
        item_lines_array
        shipment_lines_array
      end
    end

    def item_line(line_item)
      @logger.info('build line_item line')

      stock_location = get_stock_location(@stock_locations, line_item)

      line = {
        :LineNo => "#{line_item.id}-LI",
        :Description => line_item.name[0..255],
        :TaxCode => line_item.tax_category.try(:tax_code) || 'P0000000',
        :ItemCode => line_item.variant.sku,
        :Qty => line_item.quantity,
        :Amount => line_item.discounted_amount.to_f,
        :OriginCode => stock_location,
        :DestinationCode => 'Dest',
        :CustomerUsageType => order.user ? order.user.avalara_entity_use_code.try(:use_code) : '',
        :Discounted => line_item.promo_total > 0.0
      }

      @logger.debug line

      line
    end

    def item_lines_array
      @logger.info('build line_item lines')
      line_item_lines = []

      order.line_items.each do |line_item|
        line_item_lines << item_line(line_item)
      end

      @logger.info_and_debug('item_lines_array', line_item_lines)

      lines.concat(line_item_lines) unless line_item_lines.empty?
    end

    def shipment_lines_array
      @logger.info('build shipment lines')

      ship_lines = []
      order.shipments.each do |shipment|
        if shipment.tax_category
          ship_lines << shipment_line(shipment)
        end

        @logger.info_and_debug('shipment_lines_array', ship_lines)

        lines.concat(ship_lines) unless ship_lines.empty?
      end
    end

    def shipment_line(shipment)
      @logger.info('build shipment line')

      shipment_line = {
        :LineNo => "#{shipment.id}-FR",
        :ItemCode => shipment.shipping_method.name,
        :Qty => 1,
        :Amount => shipment.discounted_amount.to_f,
        :OriginCode => "#{shipment.stock_location_id}",
        :DestinationCode => 'Dest',
        :CustomerUsageType => order.user ? customer_usage_type : '',
        :Description => 'Shipping Charge',
        :TaxCode => shipment.shipping_method.tax_category.try(:tax_code) || 'FR000000'
      }

      @logger.debug shipment_line

      shipment_line
    end

    def refund_lines
      refunds = []
      order.refunds.each do |refund|
        next if refund.reimbursement.try(:reimbursement_status) == 'reimbursed'

        refund_line = {
          :LineNo => "#{refund.id}-RA",
          :ItemCode => refund.transaction_id || 'Refund',
          :Qty => 1,
          :Amount => -refund.reimbursement.return_items.sum(:pre_tax_amount).to_f,
          :OriginCode => 'Orig',
          :DestinationCode => 'Dest',
          :CustomerUsageType => order.user ? customer_usage_type : '',
          :Description => 'Refund'
        }

        @logger.debug refund_line

        refunds << refund_line
      end

      lines.concat(refunds) unless refunds.empty?
    end

    def order_stock_locations
      @logger.info('getting stock locations')

      packages = Spree::Stock::Coordinator.new(order).packages
      stock_location_ids = packages.map(&:to_shipment).map(&:stock_location_id)
      stock_locations = Spree::StockLocation.where(id: stock_location_ids)
      @logger.debug stock_locations
      stock_locations
    end

    def get_stock_location(stock_locations, line_item)
      line_item_stock_locations = stock_locations.joins(:stock_items).where(spree_stock_items: { variant_id: line_item.variant_id })

      if line_item_stock_locations.empty?
        'Orig'
      else
        "#{line_item_stock_locations.first.id}"
      end
    end

    def customer_usage_type
      order.user.avalara_entity_use_code.try(:use_code)
    end
  end
end
