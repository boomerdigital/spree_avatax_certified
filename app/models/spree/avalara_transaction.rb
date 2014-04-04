require 'logging'
require_dependency 'spree/order'
require_relative  'tax_svc'


module Spree
  class AvalaraTransaction < ActiveRecord::Base
    # To change this template use File | Settings | File Templates.
    logger = Logger.new('post_order_to_avalara.txt', 'weekly')

    #logger.level = :debug

    logger.progname = 'avalara_transaction'

    belongs_to :order

    validates :order, :presence => true

    has_one :adjustment, :as => :originator

    #has_many :cart_items, :class_name => 'SpreeAvalaraCartItem', :dependent => :destroy


    #logger.auto_flushing = true


    def rnt_tax
      @myrtntax
    end
    def amount
      @myrtntax
    end


    def lookup_avatax
      post_order_to_avalara(false)
    end


    def commit_avatax(items, order_details)
      post_order_to_avalara(false, items, order_details)
    end

    def commit_avatax_final(items, order_details)
      post_order_to_avalara(true, items, order_details)
    end


    def update_adjustment(adjustment, source)
      #if order.complete? then
      #  #now recalc the tax
      #  post_order_to_avalara(false, order.line_items, order)
      #  adjustment.update_column(:amount, rnt_tax)
      #end
      post_order_to_avalara(false, order.line_items, order)
      #rate = rnt_tax.to_f || 0 / order.item_total
      #tax  = (order.item_total) * rate
      #tax  = 0 if tax.nan?
      adjustment.update_column(:amount, rnt_tax)
    end


    #def create_cart_items
    #
    #  cart_items.clear
    #
    #  index = 0
    #
    #  order.line_items.each do |line_item|
    #
    #    cart_items.create!({
    #
    #                           :index => (index += 1),
    #
    #                           :tax_category => '20020', # TODO   CLOTHING-ACCESSORY
    #                           #if not there leave null for test
    #
    #                           :sku => line_item.variant.sku.presence || line_item.variant.id,
    #
    #                           :quantity => line_item.quantity,
    #
    #                           :price => line_item.price.to_f,
    #
    #                           :line_item => line_item
    #
    #                       })
    #
    #  end
    #
    #  cart_items.create!({
    #
    #                         :index => (index += 1),
    #
    #                         :tic => '11010',
    #
    #                         :sku => 'SHIPPING',
    #
    #                         :quantity => 1,
    #
    #                         :price => order.ship_total.to_f
    #
    #                     })
    #
    #end



    private
    def get_shipped_from_address(item_id)
      #now request from the database the item shipping location
      #will link using the spree stock locations and the spree stock items
      #stock items has fk relationship to stock locations
      stock_item = Stock_Item.find(item_id)
      shipping_address = Stock_Location.find(stock_item.stock_location_id)
      return shipping_address
    end

    def post_order_to_avalara(commit=false, orderitems=nil, order_details=nil)
      logger = Logger.new('post_order_to_avalara.txt', 'weekly')

      #logger.level = :debug

      logger.progname = 'avalara_transaction'

      logger.info 'post order to avalara'
      #Create array for line items
      tax_line_items=Array.new
      #Create array for addresses
      addresses=Array.new

      origin = JSON.parse( Spree::Config.avatax_origin )
      orig_address = Hash.new
      orig_address[:AddressCode] = "Orig"
      orig_address[:Line1] = origin["Address1"]
      orig_address[:City] = origin["City"]
      orig_address[:PostalCode] = origin["Zip5"]
      orig_address[:Country] = origin["Country"]

      logger.debug orig_address.to_xml


      i = 0
      if orderitems then
        orderitems.each do |line_item|
          #  line_item_total=line_item.price*line_item.quantity
          #  item_id = line_item.id
          # need to map the taxcodes to tax cat names
          line = Hash.new
          i += 1
          # Required Parameters
          line[:LineNo] = i
          line[:ItemCode] = line_item.variant.sku
          line[:Qty] = line_item.quantity
          line[:Amount] = line_item.total.to_f
          line[:OriginCode] = "Orig"
          line[:DestinationCode] = "Dest"

          # Best Practice Request Parameters
          line[:Description] = ""
          if line_item.tax_category.name then
            line[:TaxCode] = line_item.tax_category.name || "PC030147"
          end


          logger.debug line.to_xml

          tax_line_items<<line
        end
      end

      #OriginationAddress


      #Billing Address

      billing_address = Hash.new

      billing_address[:AddressCode] = "Dest"
      billing_address[:Line1] = order_details.shipping_address.address1
      billing_address[:Line2] = order_details.shipping_address.address2
      billing_address[:City] = order_details.shipping_address.city
      billing_address[:Region] = order_details.shipping_address.state_text
      billing_address[:Country] = Country.find(order_details.shipping_address.country_id).iso
      billing_address[:PostalCode] = order_details.shipping_address.zipcode


      logger.debug billing_address.to_xml

      #addresses=Hash.new
      addresses<<billing_address
      addresses<<orig_address


      gettaxes = {
          :CustomerCode => "APITrialCompany",
          :DocDate => Date.current.to_formatted_s(:db),

          # Best Practice Request Parameters
          :CompanyCode => "APITrialCompany", #Spree::Config.avatax_api_username,
          #:Client => "AvaTaxSample",
          :DocCode => order_details.number,
          :DetailLevel => "Tax",
          :Commit => commit,
          :DocType => "SalesInvoice",
          :Addresses => addresses,
          :Lines => tax_line_items

      }


      logger.debug gettaxes

      mytax = TaxSvc.new( Spree::Config.avatax_account || AvalaraYettings['account'],Spree::Config.avatax_license_key || AvalaraYettings['license_key'],Spree::Config.avatax_endpoint || AvalaraYettings['endpoint'])

      getTaxResult = mytax.GetTax(gettaxes)

      logger.debug getTaxResult

      if getTaxResult == 'error in Tax' then
        @myrtntax = "1.00"


      else
        if getTaxResult["ResultCode"] = "Success"
        logger.debug getTaxResult["TotalTax"].to_s
        @myrtntax = getTaxResult["TotalTax"].to_s



        end
      end
      return @myrtntax
    end

  end
end