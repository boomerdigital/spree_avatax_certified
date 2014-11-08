require 'logging'
require_dependency 'spree/order'

module Spree
  class AvalaraTransaction < ActiveRecord::Base

    belongs_to :order
    belongs_to :return_authorization
    has_one :adjustment
    validates :order, presence: true


    def rnt_tax
      @myrtntax
    end

    def amount
      @myrtntax
    end

    def lookup_avatax
      order_details = Spree::Order.find(self.order_id)
      post_order_to_avalara(false, order_details.line_items, order_details)
    end

    def commit_avatax(items, order_details,doc_id=nil,invoice_dt=nil)
      post_order_to_avalara(false, items, order_details,doc_id,invoice_dt)
    end

    def commit_avatax_final(items, order_details,doc_id=nil,invoice_dt=nil)
      post_order_to_avalara(true, items, order_details,doc_id,invoice_dt)
    end

    def update_adjustment(adjustment, source)
      logger.info("update adjustment call")

      if adjustment.state != "finalized"
        post_order_to_avalara(false, order.line_items, order)
        adjustment.update_column(:amount, rnt_tax)
      end

      if order.complete?
        post_order_to_avalara(true, order.line_items, order)
        adjustment.update_column(:amount, rnt_tax)
        adjustment.update_column(:state, "finalized")
      end

      if order.state == 'canceled'
        cancel_order_to_avalara("SalesInvoice", "DocVoided", order)
      end

      if adjustment.state == "finalized" && order.adjustments.return_authorization.exists?
        post_order_to_avalara(false, order.line_items, order, order.number.to_s + ":" + order.adjustments.return_authorization.first.id.to_s, order.completed_at)

        if rnt_tax != "0.00"
          adjustment.update_column(:amount, rnt_tax)
          adjustment.update_column(:state, "finalized")
        end
      end

      if adjustment.state == "finalized" && order.adjustments.return_authorization.exists?
        order.adjustments.return_authorization.each do |adj|
          if adj.state == "closed" || adj.state == "finalized"
            post_order_to_avalara(true, order.line_items, order, order.number.to_s + ":"  + adj.id.to_s, order.completed_at )
          end
        end

        if rnt_tax != "0.00"
          adjustment.update_column(:amount, rnt_tax)
          adjustment.update_column(:state, "finalized")
        end
      end
    end


    private

    def get_shipped_from_address(item_id)
      logger.info("shipping address get")

      stock_item = Stock_Item.find(item_id)
      shipping_address = stock_item.stock_location || nil
      return shipping_address
    end

    def cancel_order_to_avalara(doc_type="SalesInvoice", cancel_code="DocVoided", order_details=nil)
      logger.info("cancel order to avalara")

      cancelTaxRequest = {
        :CompanyCode => Spree::Config.avatax_company_code,
        :DocType => doc_type,
        :DocCode => order_details.number,
        :CancelCode => cancel_code
      }

      logger.debug cancelTaxRequest

      mytax = TaxSvc.new
      cancelTaxResult = mytax.cancel_tax(cancelTaxRequest)

      logger.debug cancelTaxResult

      if cancelTaxResult == 'error in Tax' then
        return 'Error in Tax'
      else
        if cancelTaxResult["ResultCode"] = "Success"
          logger.debug cancelTaxResult
          return cancelTaxResult
        end
      end
    end

    def post_order_to_avalara(commit=false, orderitems=nil, order_details=nil, doc_code=nil, org_ord_date=nil)
      logger.info("post order to avalara")

      tax_line_items = Array.new
      addresses = Array.new

      origin = JSON.parse(Spree::Config.avatax_origin)
      orig_address = Hash.new
      orig_address[:AddressCode] = "Orig"
      orig_address[:Line1] = origin["Address1"]
      orig_address[:City] = origin["City"]
      orig_address[:PostalCode] = origin["Zip5"]
      orig_address[:Country] = origin["Country"]
      logger.debug orig_address.to_xml

      begin
        if order_details.user_id != nil
        myuserid = order_details.user_id
        logger.debug myuserid
        myuser = Spree::User.find(myuserid)
        myusecode = Spree::AvalaraUseCodeItem.where(:id => myuser.spree_avalara_use_code_item_id).first
      end
      rescue => e
        logger.debug e
        logger.debug "error with order's user id"
      end

      i = 0

      if orderitems then

        orderitems.each do |line_item|
          line = Hash.new
          i += 1

          line[:LineNo] = i
          line[:ItemCode] = line_item.variant.sku
          line[:Qty] = line_item.quantity
          line[:Amount] = line_item.total.to_f
          line[:OriginCode] = "Orig"
          line[:DestinationCode] = "Dest"

          logger.info('about to check for User')
          logger.debug myusecode

          if myusecode
            line[:CustomerUsageType] = myusecode.use_code || ""
          end

          logger.info('after user check')

          line[:Description] = line_item.name
          if line_item.tax_category.name
            line[:TaxCode] = line_item.tax_category.description || "PC030147"
          end

          logger.info('about to check for shipped from')

          shipped_from = order_details.inventory_units.where(:variant_id => line_item.id)
          location = Spree::StockLocation.find_by(name: 'default') || Spree::StockLocation.first

          logger.info('default location')
          logger.debug location

          packages = Spree::Stock::Coordinator.new(order_details).packages

          logger.info('packages')
          logger.debug packages

          stock_loc = nil

          packages.each do |package|
            next unless package.to_shipment.stock_location.stock_items.where(:variant_id => line_item.variant.id).exists?
            stock_loc = package.to_shipment.stock_location
            logger.debug stock_loc
          end

          logger.info('checked for shipped from')

          if stock_loc
            orig_ship_address = Hash.new
            orig_ship_address[:AddressCode] = line_item.id
            orig_ship_address[:Line1] = stock_loc.address1
            orig_ship_address[:City] = stock_loc.city
            orig_ship_address[:PostalCode] = stock_loc.zipcode
            orig_ship_address[:Country] = Country.find(stock_loc.country_id).iso

            line[:OriginCode] = line_item.id
            logger.debug orig_ship_address.to_xml

            addresses<<orig_ship_address
          elsif location
            orig_ship_address = Hash.new
            orig_ship_address[:AddressCode] = line_item.id
            orig_ship_address[:Line1] = location.address1
            orig_ship_address[:City] = location.city
            orig_ship_address[:PostalCode] = location.zipcode
            orig_ship_address[:Country] = Country.find(location.country_id).iso

            line[:OriginCode] = line_item.id
            logger.debug orig_ship_address.to_xml
            addresses<<orig_ship_address
          end

          logger.debug line.to_xml

          tax_line_items<<line
        end
      end

      logger.info('running order details')
      if order_details then
        logger.info('order adjustments')

        order_details.adjustments.shipping.each do |adj|

          line = Hash.new
          i += 1

          line[:LineNo] = i
          line[:ItemCode] = "Shipping"
          line[:Qty] = "0"
          line[:Amount] = adj.amount.to_f
          line[:OriginCode] = "Orig"
          line[:DestinationCode] = "Dest"

          if myusecode
            line[:CustomerUsageType] = myusecode.use_code || ""
          end

          line[:Description] = adj.label
          line[:TaxCode] = Spree::ShippingMethod.where(:id => adj.originator_id).first.tax_use_code

          logger.debug line.to_xml

          tax_line_items<<line
        end

        order_details.adjustments.promotion.each do |adj|

          line = Hash.new
          i += 1

          line[:LineNo] = i
          line[:ItemCode] = "Promotion"
          line[:Qty] = "0"
          line[:Amount] = adj.amount.to_f
          line[:OriginCode] = "Orig"
          line[:DestinationCode] = "Dest"

          if myusecode
            line[:CustomerUsageType] = myusecode.use_code || ""
          end

          line[:Description] = adj.label
          line[:TaxCode] = ""

          logger.debug line.to_xml

          tax_line_items<<line
        end

        order_details.adjustments.return_authorization.each do |adj|

          line = Hash.new
          i += 1

          line[:LineNo] = i
          line[:ItemCode] = "Return Authorization"
          line[:Qty] = "0"
          line[:Amount] = adj.amount.to_f
          line[:OriginCode] = "Orig"
          line[:DestinationCode] = "Dest"

          if myusecode
            line[:CustomerUsageType] = myusecode.use_code || ""
          end

          line[:Description] = adj.label
          line[:TaxCode] = ""

          logger.debug line.to_xml

          tax_line_items<<line
        end
      end

      billing_address = Hash.new

      billing_address[:AddressCode] = "Dest"
      billing_address[:Line1] = order_details.bill_address.address1
      billing_address[:Line2] = order_details.bill_address.address2
      billing_address[:City] = order_details.bill_address.city
      billing_address[:Region] = order_details.bill_address.state_text
      billing_address[:Country] = Country.find(order_details.bill_address.country_id).iso
      billing_address[:PostalCode] = order_details.bill_address.zipcode

      logger.debug billing_address.to_xml

      addresses<<billing_address
      addresses<<orig_address

      gettaxes = {
        :CustomerCode => Spree::Config.avatax_customer_code,
        :DocDate => org_ord_date ? org_ord_date : Date.current.to_formatted_s(:db),

        :CompanyCode => Spree::Config.avatax_company_code,
        :CustomerUsageType => myusecode ? myusecode.usecode : "",
        :ExemptionNo => myuser ? myuser.exemption_number : "",
        :Client =>  Spree::Config.avatax_client_version || "SpreeExtV1.0",
        :DocCode => doc_code ? doc_code : order_details.number,

        :ReferenceCode => order_details.number,
        :DetailLevel => "Tax",
        :Commit => commit,
        :DocType => "SalesInvoice",
        :Addresses => addresses,
        :Lines => tax_line_items
      }

      logger.debug gettaxes

      mytax = TaxSvc.new

      getTaxResult = mytax.get_tax(gettaxes)

      logger.debug getTaxResult

      if getTaxResult == 'error in Tax' then
        @myrtntax = "0.00"
      else
        if getTaxResult["ResultCode"] = "Success"
          logger.debug getTaxResult["TotalTax"].to_s
          @myrtntax = getTaxResult["TotalTax"].to_s
        end
      end
      return @myrtntax
    end
  end

  private

  def logger
    AvataxHelper::AvataxLog.new("post_order_to_avalara", __FILE__)
  end
end
