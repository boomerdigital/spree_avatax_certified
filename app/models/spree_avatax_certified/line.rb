module SpreeAvataxCertified
  class Line
    attr_reader :order, :invoice_type, :lines

    def initialize(order, invoice_type)
      @order = order
      @invoice_type = invoice_type
      @lines = []
      @logger ||= AvataxHelper::AvataxLog.new('avalara_order_lines', 'SpreeAvataxCertified::Line', 'building lines')
      build_lines
    end

    def build_lines
      @logger.info('build lines')

      if invoice_type == 'ReturnInvoice' || invoice_type == 'ReturnOrder'
        return_authorization_lines
      else
        item_lines
        shipment_lines
      end
    end

    def item_lines
      @logger.info('build line_item lines')
      line_item_lines = []

      @logger.info('getting stock locations')

      stock_location_ids = Spree::Stock::Coordinator.new(order).packages.map(&:to_shipment).map(&:stock_location_id)
      stock_locations = Spree::StockLocation.where(id: stock_location_ids)

      @logger.debug stock_locations

      order.line_items.each do |line_item|

        stock_location = get_stock_location(stock_locations, line_item)

        line = {
          :LineNo => "#{line_item.id}-LI",
          :Description => line_item.name[0..255],
          :TaxCode => line_item.tax_category.try(:description) || 'P0000000',
          :ItemCode => line_item.variant.sku,
          :Qty => line_item.quantity,
          :Amount => line_item.discounted_amount.to_f,
          :OriginCode => stock_location,
          :DestinationCode => 'Dest',
          :CustomerUsageType => order.user ? order.user.avalara_entity_use_code.try(:use_code) : '',
          :Discounted => line_item.promo_total > 0.0
        }

        @logger.debug line

        line_item_lines << line
      end

      lines.concat(line_item_lines) unless line_item_lines.empty?
    end

    def shipment_lines
      @logger.info('build shipment lines')

      ship_lines = []
      order.shipments.each do |shipment|
        if shipment.tax_category
          shipment_line = {
            :LineNo => "#{shipment.id}-FR",
            :ItemCode => shipment.shipping_method.name,
            :Qty => 1,
            :Amount => shipment.discounted_amount.to_f,
            :OriginCode => "#{shipment.stock_location_id}",
            :DestinationCode => 'Dest',
            :CustomerUsageType => order.user ? order.user.avalara_entity_use_code.try(:use_code) : '',
            :Description => 'Shipping Charge',
            :TaxCode => shipment.shipping_method.tax_category.try(:description) || 'FR000000',
          }

          @logger.debug shipment_line

          ship_lines << shipment_line
        end

        lines.concat(ship_lines) unless ship_lines.empty?
      end
    end

    def return_authorization_lines
      @logger.info('build return return_authorization lines')

      return_auth_lines = []

      order.return_authorizations.each do |return_auth|
        next if return_auth.state == 'received'

        return_auth_line = {
          :LineNo => "#{return_auth.id}-RA",
          :ItemCode => return_auth.number || 'return_authorization',
          :Qty => 1,
          :Amount => -return_auth.amount.to_f,
          :OriginCode => 'Orig',
          :DestinationCode => 'Dest',
          :CustomerUsageType => order.user ? order.user.avalara_entity_use_code.try(:use_code) : '',
          :Description => 'return_authorization'
        }

        @logger.debug return_auth_line
      end

      lines.concat(return_auth_lines) unless return_auth_lines.empty?
    end

    def get_stock_location(stock_locations, line_item)
      line_item_stock_locations = stock_locations.joins(:stock_items).where(spree_stock_items: {variant_id: line_item.variant_id})

      if line_item_stock_locations.empty?
        'Orig'
      else
        "#{line_item_stock_locations.first.id}"
      end
    end
  end
end
