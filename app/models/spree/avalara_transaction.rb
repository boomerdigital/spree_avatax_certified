require 'logging'
require_dependency 'spree/order'

module Spree
  class AvalaraTransaction < ActiveRecord::Base
    AVALARA_TRANSACTION_LOGGER = AvataxHelper::AvataxLog.new('post_order_to_avalara', __FILE__)

    belongs_to :order
    belongs_to :return_authorization
    validates :order, presence: true
    validates :order_id, uniqueness: true
    has_many :adjustments, as: :source

    def lookup_avatax
      post_order_to_avalara(false, 'SalesOrder')
    end

    def commit_avatax(invoice_dt = nil, return_auth = nil)
      if tax_calculation_enabled?
        if %w(ReturnInvoice ReturnOrder).include?(invoice_dt)
          post_return_to_avalara(false, invoice_dt, return_auth)
        else
          post_order_to_avalara(false, invoice_dt)
        end
      else
        { TotalTax: '0.00' }
      end
    end

    def commit_avatax_final(invoice_dt = nil, return_auth = nil)
      if document_committing_enabled?
        if tax_calculation_enabled?
          if %w(ReturnInvoice ReturnOrder).include?(invoice_dt)
            post_return_to_avalara(true, invoice_dt, return_auth)
          else
            post_order_to_avalara(true, invoice_dt)
          end
        else
          { TotalTax: '0.00' }
        end
      else
        AVALARA_TRANSACTION_LOGGER.debug 'avalara document committing disabled'
        'avalara document committing disabled'
      end
    end

    def cancel_order
      cancel_order_to_avalara('SalesInvoice') if tax_calculation_enabled?
    end

    def adjust_avatax
      adjust_order_to_avalara if tax_calculation_enabled?
    end

    private

    def adjust_order_to_avalara
      AVALARA_TRANSACTION_LOGGER.info('post adjust order to avalara')
      avatax_address = SpreeAvataxCertified::Address.new(order)
      avatax_line = SpreeAvataxCertified::Line.new(order, 'SalesInvoice')

      gettaxes = {
        DocCode: order.number,
        Discount: order.adjustments.eligible.promotion.sum(:amount).abs.to_s,
        Commit: true,
        DocType: 'SalesInvoice',
        Addresses: avatax_address.addresses,
        Lines: avatax_line.lines
      }.merge(base_tax_hash)

      AVALARA_TRANSACTION_LOGGER.debug gettaxes

      mytax = TaxSvc.new
      tax_result = mytax.adjust_tax(gettaxes)
      response = SpreeAvataxCertified::Response.new(tax_result)

      AVALARA_TRANSACTION_LOGGER.info_and_debug('tax result', tax_result)

      response.tax_result
    end

    def cancel_order_to_avalara(doc_type = 'SalesInvoice')
      AVALARA_TRANSACTION_LOGGER.info('cancel order to avalara')

      cancel_tax_request = {
        CompanyCode: Spree::Config.avatax_company_code,
        DocType: doc_type,
        DocCode: order.number,
        CancelCode: 'DocVoided'
      }

      mytax = TaxSvc.new
      cancel_tax_result = mytax.cancel_tax(cancel_tax_request)

      AVALARA_TRANSACTION_LOGGER.debug cancel_tax_result

      if cancel_tax_result == 'Error in Cancel Tax'
        return 'Error in Cancel Tax'
      else
        return cancel_tax_result
      end
    end

    def post_order_to_avalara(commit = false, invoice_detail = nil)
      AVALARA_TRANSACTION_LOGGER.info('post order to avalara')
      avatax_address = SpreeAvataxCertified::Address.new(order)
      avatax_line = SpreeAvataxCertified::Line.new(order, invoice_detail)

      response = avatax_address.validate

      unless response.nil?
        if response['ResultCode'] == 'Success'
          AVALARA_TRANSACTION_LOGGER.info('Address Validation Success')
        else
          AVALARA_TRANSACTION_LOGGER.info('Address Validation Failed')
        end
      end

      gettaxes = {
        DocCode: order.number,
        Discount: order.adjustments.eligible.promotion.sum(:amount).abs.to_s,
        Commit: commit,
        DocType: invoice_detail ? invoice_detail : 'SalesOrder',
        Addresses: avatax_address.addresses,
        Lines: avatax_line.lines
      }.merge(base_tax_hash)

      AVALARA_TRANSACTION_LOGGER.debug gettaxes

      mytax = TaxSvc.new
      tax_result = mytax.get_tax(gettaxes)
      response = SpreeAvataxCertified::Response.new(tax_result)

      AVALARA_TRANSACTION_LOGGER.info_and_debug('tax result', tax_result)

      response.tax_result
    end

    def post_return_to_avalara(commit = false, invoice_detail = nil, return_auth = nil)
      AVALARA_TRANSACTION_LOGGER.info('starting post return order to avalara')

      avatax_address = SpreeAvataxCertified::Address.new(order)
      avatax_line = SpreeAvataxCertified::Line.new(order, invoice_detail, return_auth)

      taxoverride = {
        TaxOverrideType: 'None',
        Reason: 'Return',
        TaxDate: order.completed_at.strftime('%F')
      }

      gettaxes = {
        DocCode: order.number.to_s + '.' + return_auth.id.to_s,
        Commit: commit,
        DocType: invoice_detail ? invoice_detail : 'ReturnOrder',
        Addresses: avatax_address.addresses,
        Lines: avatax_line.lines
      }.merge(base_tax_hash)

      gettaxes[:TaxOverride] = taxoverride

      AVALARA_TRANSACTION_LOGGER.debug gettaxes

      mytax = TaxSvc.new
      tax_result = mytax.get_tax(gettaxes)
      response = SpreeAvataxCertified::Response.new(tax_result)

      AVALARA_TRANSACTION_LOGGER.info_and_debug('tax result', tax_result)

      response.tax_result
    end

    def base_tax_hash
      doc_date = order.completed? ? order.completed_at.strftime('%F') : Date.today.strftime('%F')
      {
        CustomerCode: customer_code,
        DocDate: doc_date,
        CompanyCode: Spree::Config.avatax_company_code,
        CustomerUsageType: customer_usage_type,
        ExemptionNo: order.user.try(:exemption_number),
        Client:  avatax_client_version,
        ReferenceCode: order.number,
        DetailLevel: 'Tax'
      }
    end

    def customer_usage_type
      order.user ? order.user.avalara_entity_use_code.try(:use_code) : ''
    end

    def customer_code
      order.user ? order.user.id : order.email
    end

    def avatax_client_version
      AVATAX_CLIENT_VERSION || 'SpreeExtV2.4'
    end

    def document_committing_enabled?
      Spree::Config.avatax_document_commit
    end

    def tax_calculation_enabled?
      Spree::Config.avatax_tax_calculation
    end
  end
end
