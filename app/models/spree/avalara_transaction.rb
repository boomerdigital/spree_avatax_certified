require 'logging'
require_dependency 'spree/order'

module Spree
  class AvalaraTransaction < ActiveRecord::Base
    AVALARA_TRANSACTION_LOGGER = AvataxHelper::AvataxLog.new("post_order_to_avalara", __FILE__)

    belongs_to :order
    belongs_to :return_authorization
    validates :order, presence: true
    validates :order_id, uniqueness: true
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

    def post_order_to_avalara(commit=false, orderitems=nil, order_details=nil, doc_code=nil, org_ord_date=nil, invoice_detail=nil)
      AVALARA_TRANSACTION_LOGGER.info("post order to avalara")

      avatax_address = SpreeAvataxCertified::Address.new(order_details)
      avatax_line = SpreeAvataxCertified::Line.new(order_details, invoice_detail)

      AVALARA_TRANSACTION_LOGGER.debug avatax_address

      origin = JSON.parse(Spree::Config.avatax_origin)

      response = avatax_address.validate

      if response != nil
        if response["ResultCode"] == "Success"
          AVALARA_TRANSACTION_LOGGER.info("Address Validation Success")
        else
          AVALARA_TRANSACTION_LOGGER.info("Address Validation Failed")
        end
      end

      taxoverride = {}

      if invoice_detail == 'ReturnInvoice' || invoice_detail == 'ReturnOrder'
        taxoverride[:TaxOverrideType] = 'TaxDate'
        taxoverride[:Reason] = 'Adjustment for return'
        taxoverride[:TaxDate] = org_ord_date
        taxoverride[:TaxAmount] = '0'
      end

      gettaxes = {
        :CustomerCode => order_details.user ? order_details.user.id : "Guest",
        :DocDate => org_ord_date ? org_ord_date : Date.current.to_formatted_s(:db),

        :CompanyCode => Spree::Config.avatax_company_code,
        :CustomerUsageType => order.user ? order.user.avalara_entity_use_code.try(:use_code) : '',
        :ExemptionNo => order_details.user.try(:exemption_number),
        :Client =>  AVATAX_CLIENT_VERSION || "SpreeExtV2.3",
        :DocCode => doc_code ? doc_code : order_details.number,

        :Discount => order_details.all_adjustments.where(source_type: "Spree::PromotionAction").any? ? order_details.all_adjustments.where(source_type: "Spree::PromotionAction").pluck(:amount).reduce(&:+).to_f.abs : 0,

        :ReferenceCode => order_details.number,
        :DetailLevel => "Tax",
        :Commit => commit,
        :DocType => invoice_detail ? invoice_detail : "SalesInvoice",
        :Addresses => avatax_address.addresses,
        :Lines => avatax_line.lines
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
