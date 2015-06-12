require 'logging'
require_dependency 'spree/order'

module Spree
  class AvalaraTransaction < ActiveRecord::Base
    AVALARA_TRANSACTION_LOGGER = AvataxHelper::AvataxLog.new("post_order_to_avalara", __FILE__)

    belongs_to :order
    belongs_to :return_authorization
    validates :order, presence: true
    has_many :adjustments, as: :source

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

    def commit_avatax(items, order_details, doc_id=nil, org_ord_date=nil, invoice_dt=nil)
      post_order_to_avalara(false, items, order_details, doc_id, org_ord_date, invoice_dt)
    end

    def commit_avatax_final(items, order_details,doc_id=nil, org_ord_date=nil, invoice_dt=nil)
      if document_committing_enabled?
        post_order_to_avalara(true, items, order_details, doc_id, org_ord_date,invoice_dt)
      else
        AVALARA_TRANSACTION_LOGGER.debug "avalara document committing disabled"
        "avalara document committing disabled"
      end
    end

    def check_status(order)
      if order.state == 'canceled'
        cancel_order_to_avalara("SalesInvoice", "DocVoided", order)
      end
    end

    def update_adjustment(adjustment, source)
      AVALARA_TRANSACTION_LOGGER.info("update adjustment call")

      if adjustment.state != "closed"
        commit_avatax(order.line_items, order)
        adjustment.update_column(:amount, rnt_tax)
      end

      if order.complete?
        commit_avatax_final(order.line_items, order)
        adjustment.update_column(:amount, rnt_tax)
        adjustment.update_column(:state, "closed")
      end

      if order.state == 'canceled'
        cancel_order_to_avalara("SalesInvoice", "DocVoided", order)
      end

      if adjustment.state == "closed" && order.adjustments.return_authorization.exists?
        commit_avatax(order.line_items, order, order.number.to_s + ":" + order.adjustments.return_authorization.first.id.to_s, order.completed_at)

        if rnt_tax != "0.00"
          adjustment.update_column(:amount, rnt_tax)
          adjustment.update_column(:state, "closed")
        end
      end

      if adjustment.state == "closed" && order.adjustments.return_authorization.exists?
        order.adjustments.return_authorization.each do |adj|
          if adj.state == "closed" || adj.state == "closed"
            commit_avatax_final(order.line_items, order, order.number.to_s + ":"  + adj.id.to_s, order.completed_at )
          end
        end

        if rnt_tax != "0.00"
          adjustment.update_column(:amount, rnt_tax)
          adjustment.update_column(:state, "closed")
        end
      end
    end


    private

    def get_shipped_from_address(item_id)
      AVALARA_TRANSACTION_LOGGER.info("shipping address get")

      stock_item = Stock_Item.find(item_id)
      shipping_address = stock_item.stock_location || nil
      return shipping_address
    end

    def cancel_order_to_avalara(doc_type="SalesInvoice", cancel_code="DocVoided", order_details=nil)
      AVALARA_TRANSACTION_LOGGER.info("cancel order to avalara")

      cancelTaxRequest = {
        :CompanyCode => Spree::Config.avatax_company_code,
        :DocType => doc_type,
        :DocCode => order_details.number,
        :CancelCode => cancel_code
      }

      AVALARA_TRANSACTION_LOGGER.debug cancelTaxRequest

      mytax = TaxSvc.new
      cancelTaxResult = mytax.cancel_tax(cancelTaxRequest)

      AVALARA_TRANSACTION_LOGGER.debug cancelTaxResult

      if cancelTaxResult == 'error in Tax' then
        return 'Error in Tax'
      else
        if cancelTaxResult["ResultCode"] = "Success"
          AVALARA_TRANSACTION_LOGGER.debug cancelTaxResult
          return cancelTaxResult
        end
      end
    end


    def origin_address
      origin = JSON.parse(Spree::Config.avatax_origin)
      orig_address = Hash.new
      orig_address[:AddressCode] = "Orig"
      orig_address[:Line1] = origin["Address1"]
      orig_address[:City] = origin["City"]
      orig_address[:PostalCode] = origin["Zip5"]
      orig_address[:Country] = origin["Country"]
      AVALARA_TRANSACTION_LOGGER.debug orig_address.to_xml
      return orig_address
    end

    def origin_ship_address(line_item, origin)
      orig_ship_address = Hash.new
      orig_ship_address[:AddressCode] = line_item.id
      orig_ship_address[:Line1] = origin.address1
      orig_ship_address[:City] = origin.city
      orig_ship_address[:PostalCode] = origin.zipcode
      orig_ship_address[:Country] = Country.find(origin.country_id).iso

      AVALARA_TRANSACTION_LOGGER.debug orig_ship_address.to_xml
      return orig_ship_address
    end

    def order_shipping_address
      if order.ship_address.nil?
        shipping_address = Hash.new
        shipping_address[:AddressCode] = "Dest"
        shipping_address[:Line1] = order.bill_address.address1
        shipping_address[:Line2] = order.bill_address.address2
        shipping_address[:City] = order.bill_address.city
        shipping_address[:Region] = order.bill_address.state_name
        shipping_address[:Country] = Country.find(order.bill_address.country_id).iso
        shipping_address[:PostalCode] = order.bill_address.zipcode

        AVALARA_TRANSACTION_LOGGER.debug shipping_address.to_xml
        return shipping_address
      else
        shipping_address = Hash.new
        shipping_address[:AddressCode] = "Dest"
        shipping_address[:Line1] = order.ship_address.address1
        shipping_address[:Line2] = order.ship_address.address2
        shipping_address[:City] = order.ship_address.city
        shipping_address[:Region] = order.ship_address.state_name
        shipping_address[:Country] = Country.find(order.ship_address.country_id).iso
        shipping_address[:PostalCode] = order.ship_address.zipcode

        AVALARA_TRANSACTION_LOGGER.debug shipping_address.to_xml
        return shipping_address
      end
    end

    def stock_location(packages, line_item)
      stock_loc = nil

      packages.each do |package|
        next unless package.to_shipment.stock_location.stock_items.where(:variant_id => line_item.variant.id).exists?
        stock_loc = package.to_shipment.stock_location
        AVALARA_TRANSACTION_LOGGER.debug stock_loc
      end
      return stock_loc
    end

    def shipment_line(shipment)
      line = Hash.new
      line[:LineNo] = "#{shipment.id}-FR"
      line[:ItemCode] = "Shipping"
      line[:Qty] = 1
      line[:Amount] = shipment.cost.to_f
      line[:OriginCode] = "Orig"
      line[:DestinationCode] = "Dest"
      line[:CustomerUsageType] = myusecode.try(:use_code)
      line[:Description] = "Shipping Charge"
      line[:TaxCode] = shipment.shipping_method.tax_code || "FR000000"

      AVALARA_TRANSACTION_LOGGER.debug line.to_xml
      return line
    end

    # Not used anymore
    # def promotion_line(promo)
    #   line = Hash.new
    #   line[:LineNo] = "#{promo.id}-PR"
    #   line[:ItemCode] = "Promotion"
    #   line[:Qty] = 0
    #   line[:Amount] = promo.amount.to_f
    #   line[:Discounted] = true
    #   line[:OriginCode] = "Orig"
    #   line[:DestinationCode] = "Dest"
    #   line[:CustomerUsageType] = myusecode.try(:use_code)
    #   line[:Description] = promo.label
    #   line[:TaxCode] = ""

    #   AVALARA_TRANSACTION_LOGGER.debug line.to_xml
    #   return line
    # end

    def myusecode
      begin
        if order.user_id != nil
          myuser = order.user
          AVALARA_TRANSACTION_LOGGER.debug myuser
          unless myuser.avalara_entity_use_code_id.nil?
            return Spree::AvalaraEntityUseCode.find(myuser.avalara_entity_use_code_id)
          else
            return nil
          end
        end
      rescue => e
        AVALARA_TRANSACTION_LOGGER.debug e
        AVALARA_TRANSACTION_LOGGER.debug "error with order's user id"
      end
    end

    def backup_stock_location(origin)
      location = Spree::StockLocation.find_by(name: 'default') || Spree::StockLocation.first

      if location.nil?
        location = create_stock_location_from_origin(origin)
        AVALARA_TRANSACTION_LOGGER.info('avatax origin location created')
      elsif location.zipcode.blank? || (location.city.nil? && location.state_name.nil?)
        update_location_with_origin(location, origin)
        AVALARA_TRANSACTION_LOGGER.info('avatax origin location updated default')
      else
        AVALARA_TRANSACTION_LOGGER.info('default location')
      end

      location
    end

    def create_stock_location_from_origin(origin)
      attributes = address_attributes_from_origin(origin)
      Spree::StockLocation.create(attributes.merge(name: 'avatax origin'))
    end

    def update_location_with_origin(location, origin)
      location.update_attributes(address_attributes_from_origin(origin))
    end

    def address_attributes_from_origin(origin)
      {
        address1: origin["Address1"],
        address2: origin["Address2"],
        city: origin["City"],
        state_id: Spree::State.find_by_name(origin["Region"]).id,
        state_name: origin["Region"],
        zipcode: origin["Zip5"],
        country_id: Spree::State.find_by_name(origin["Region"]).country_id
      }
    end

    def post_order_to_avalara(commit=false, orderitems=nil, order_details=nil, doc_code=nil, org_ord_date=nil, invoice_detail=nil)
      AVALARA_TRANSACTION_LOGGER.info("post order to avalara")
      address_validator = AddressSvc.new
      tax_line_items = Array.new
      addresses = Array.new

      origin = JSON.parse(Spree::Config.avatax_origin)

      i = 0

      if orderitems then
        unless invoice_detail == "ReturnInvoice" || invoice_detail == "ReturnOrder"
          orderitems.each do |line_item|
            line = Hash.new
            i += 1

            line[:LineNo] = line_item.id
            line[:ItemCode] = line_item.variant.sku
            line[:Qty] = line_item.quantity
            line[:Amount] = line_item.price.to_f
            line[:OriginCode] = "Orig"
            line[:DestinationCode] = "Dest"

            AVALARA_TRANSACTION_LOGGER.info('about to check for User')
            AVALARA_TRANSACTION_LOGGER.debug myusecode

            if myusecode
              line[:CustomerUsageType] = myusecode.try(:use_code)
            end

            if line_item.promo_total.to_f != 0
              line[:Discounted] = true
            elsif order_details.all_adjustments.where(source_type: "Spree::PromotionAction").where(adjustable_type: "Spree::Order")
              line[:Discounted] = true
            else
              line[:Discounted] = false
            end

            AVALARA_TRANSACTION_LOGGER.info('after user check')

            line[:Description] = line_item.name
            line[:TaxCode] = line_item.tax_category.try(:description) || "P0000000"

            AVALARA_TRANSACTION_LOGGER.info('about to check for shipped from')

            shipped_from = order_details.inventory_units.where(:variant_id => line_item.id)

            packages = Spree::Stock::Coordinator.new(order_details).packages

            AVALARA_TRANSACTION_LOGGER.info('packages')
            AVALARA_TRANSACTION_LOGGER.debug packages
            AVALARA_TRANSACTION_LOGGER.debug backup_stock_location(origin)
            AVALARA_TRANSACTION_LOGGER.info('checked for shipped from')


            if stock_location(packages, line_item)
              addresses<<origin_ship_address(line_item, stock_location(packages, line_item))
            elsif backup_stock_location(origin)
              addresses<<origin_ship_address(line_item, backup_stock_location(origin))
            end

            line[:OriginCode] = line_item.id
            AVALARA_TRANSACTION_LOGGER.debug line.to_xml

            tax_line_items<<line
          end
        end
      end

      AVALARA_TRANSACTION_LOGGER.info('running order details')
      if order_details then
        AVALARA_TRANSACTION_LOGGER.info('order adjustments')
        unless invoice_detail == "ReturnInvoice" || invoice_detail == "ReturnOrder"

          order_details.shipments.each do |shipment|
            tax_line_items<<shipment_line(shipment)
          end

          # order_details.all_adjustments.promotion.each do |adj|
          #   tax_line_items<<promotion_line(adj)
          # end
        end

        order_details.return_authorizations.each do |return_auth|

          line = Hash.new
          i += 1
          line[:LineNo] = "#{i}-RA"
          line[:ItemCode] = "Return Authorization"
          line[:Qty] = 1
          if invoice_detail == "ReturnInvoice" || invoice_detail == "ReturnOrder"
            line[:Amount] = -return_auth.amount.to_f
          else
            line[:Amount] = return_auth.amount.to_f

          end
          line[:OriginCode] = "Orig"
          line[:DestinationCode] = "Dest"

          if myusecode
            line[:CustomerUsageType] = myusecode.try(:use_code)
          end

          line[:Description] = return_auth.reason
          line[:TaxCode] = ""

          AVALARA_TRANSACTION_LOGGER.debug line.to_xml

          tax_line_items<<line
        end
      end

      response = address_validator.validate(order_details.ship_address)

      if response != nil
        if response["ResultCode"] == "Success"
          AVALARA_TRANSACTION_LOGGER.info("Address Validation Success")
        else
          AVALARA_TRANSACTION_LOGGER.info("Address Validation Failed")
        end
      end
      addresses<<order_shipping_address
      addresses<<origin_address

      taxoverride = Hash.new

      if invoice_detail == "ReturnInvoice" || invoice_detail == "ReturnOrder"
        taxoverride[:TaxOverrideType] = "TaxDate"
        taxoverride[:Reason] = "Adjustment for return"
        taxoverride[:TaxDate] = org_ord_date
        taxoverride[:TaxAmount] = "0"
      end

      gettaxes = {
        :CustomerCode => order_details.user ? order_details.user.id : "Guest",
        :DocDate => org_ord_date ? org_ord_date : Date.current.to_formatted_s(:db),

        :CompanyCode => Spree::Config.avatax_company_code,
        :CustomerUsageType => myusecode.try(:use_code),
        :ExemptionNo => order_details.user.try(:exemption_number),
        :Client =>  AVATAX_CLIENT_VERSION || "SpreeExtV2.3",
        :DocCode => doc_code ? doc_code : order_details.number,

        :Discount => order_details.all_adjustments.where(source_type: "Spree::PromotionAction").any? ? order_details.all_adjustments.where(source_type: "Spree::PromotionAction").pluck(:amount).reduce(&:+).to_f.abs : 0,

        :ReferenceCode => order_details.number,
        :DetailLevel => "Tax",
        :Commit => commit,
        :DocType => invoice_detail ? invoice_detail : "SalesInvoice",
        :Addresses => addresses,
        :Lines => tax_line_items
      }

      unless taxoverride.empty?
        gettaxes[:TaxOverride] = taxoverride
      end

      AVALARA_TRANSACTION_LOGGER.debug gettaxes

      mytax = TaxSvc.new

      getTaxResult = mytax.get_tax(gettaxes)

      AVALARA_TRANSACTION_LOGGER.debug getTaxResult

      if getTaxResult == 'error in Tax' then
        @myrtntax = { TotalTax: "0.00" }
      else
        if getTaxResult["ResultCode"] = "Success"
          AVALARA_TRANSACTION_LOGGER.info "total tax"
          AVALARA_TRANSACTION_LOGGER.debug getTaxResult["TotalTax"].to_s
          @myrtntax = getTaxResult
        end
      end
      return @myrtntax
    end
    def document_committing_enabled?
      Spree::Config.avatax_document_commit
    end
  end
end
