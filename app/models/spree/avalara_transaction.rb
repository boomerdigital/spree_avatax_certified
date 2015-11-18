require 'logging'
require_dependency 'spree/order'

module Spree
  class AvalaraTransaction < ActiveRecord::Base
    AVALARA_TRANSACTION_LOGGER = AvataxHelper::AvataxLog.new('post_order_to_avalara', __FILE__)

    belongs_to :order
    belongs_to :reimbursement
    belongs_to :refund
    validates :order, presence: true
    validates :order_id, uniqueness: true
    has_many :adjustments, as: :source

    def lookup_avatax
      post_order_to_avalara(false, 'SalesOrder')
    end

    def commit_avatax(invoice_dt = nil, refund_id = nil)
      if tax_calculation_enabled?
        if invoice_dt == 'ReturnInvoice'
          post_return_to_avalara(false, invoice_dt, refund_id)
        else
          post_order_to_avalara(false, invoice_dt)
        end
      else
        { TotalTax: '0.00' }
      end
    end

    def commit_avatax_final(invoice_dt = nil, refund_id = nil)
      if document_committing_enabled?
        if tax_calculation_enabled?
          if invoice_dt == 'ReturnInvoice'
            post_return_to_avalara(true, invoice_dt, refund_id)
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
      cancel_order_to_avalara('SalesInvoice', 'DocVoided')
    end

    private

    def cancel_order_to_avalara(doc_type = 'SalesInvoice', cancel_code = 'DocVoided')
      AVALARA_TRANSACTION_LOGGER.info('cancel order to avalara')

      cancel_tax_request = {
        CompanyCode: Spree::Config.avatax_company_code,
        DocType: doc_type,
        DocCode: order.number,
        CancelCode: cancel_code
      }

      AVALARA_TRANSACTION_LOGGER.debug cancel_tax_request

      mytax = TaxSvc.new
      cancel_tax_result = mytax.cancel_tax(cancel_tax_request)

      AVALARA_TRANSACTION_LOGGER.debug cancel_tax_result

      if cancel_tax_result == 'error in Tax'
        return 'Error in Tax'
      else
        if cancel_tax_result['ResultCode'] == 'Success'
          AVALARA_TRANSACTION_LOGGER.debug cancel_tax_result
          return cancel_tax_result
        end
      end
    end

    def post_order_to_avalara(commit = false, invoice_detail = nil)
      AVALARA_TRANSACTION_LOGGER.info('post order to avalara')
      avatax_address = SpreeAvataxCertified::Address.new(order)
      avatax_line = SpreeAvataxCertified::Line.new(order, invoice_detail)

      AVALARA_TRANSACTION_LOGGER.debug avatax_address
      AVALARA_TRANSACTION_LOGGER.debug avatax_line

      response = avatax_address.validate

      unless response.nil?
        if response['ResultCode'] == 'Success'
          AVALARA_TRANSACTION_LOGGER.info('Address Validation Success')
        else
          AVALARA_TRANSACTION_LOGGER.info('Address Validation Failed')
        end
      end

      gettaxes = {
        CustomerCode: customer_code,
        DocDate: Date.today.strftime('%F'),

        CompanyCode: Spree::Config.avatax_company_code,
        CustomerUsageType: customer_usage_type,
        ExemptionNo: order.user.try(:exemption_number),
        Client:  AVATAX_CLIENT_VERSION || 'SpreeExtV3.0',
        DocCode: order.number,

        Discount: order.all_adjustments.where(source_type: 'Spree::PromotionAction').any? ? order.all_adjustments.where(source_type: 'Spree::PromotionAction').pluck(:amount).reduce(&:+).to_f.abs : 0,

        ReferenceCode: order.number,
        DetailLevel: 'Tax',
        Commit: commit,
        DocType: invoice_detail ? invoice_detail : 'SalesInvoice',
        Addresses: avatax_address.addresses,
        Lines: avatax_line.lines
      }

      AVALARA_TRANSACTION_LOGGER.debug gettaxes

      mytax = TaxSvc.new

      AVALARA_TRANSACTION_LOGGER.info '********** hitting the api'

      get_tax_result = mytax.get_tax(gettaxes)

      AVALARA_TRANSACTION_LOGGER.debug get_tax_result

      if get_tax_result == 'error in Tax'
        @myrtntax = { TotalTax: '0.00' }
      else
        if get_tax_result['ResultCode'] == 'Success'
          AVALARA_TRANSACTION_LOGGER.info 'total tax'
          AVALARA_TRANSACTION_LOGGER.debug get_tax_result['TotalTax'].to_s
          @myrtntax = get_tax_result
        end
      end
      @myrtntax
    end

    def post_return_to_avalara(commit = false, invoice_detail = nil, refund_id = nil)
      AVALARA_TRANSACTION_LOGGER.info('starting post return order to avalara')

      avatax_address = SpreeAvataxCertified::Address.new(order)
      avatax_line = SpreeAvataxCertified::Line.new(order, invoice_detail)

      taxoverride = {
        TaxOverrideType: 'TaxDate',
        Reason: 'Adjustment for return',
        TaxDate: order.completed_at.strftime('%F'),
        TaxAmount: '0'
      }

      gettaxes = {
        CustomerCode: customer_code,
        DocDate: Date.today.strftime('%F'),

        CompanyCode: Spree::Config.avatax_company_code,
        CustomerUsageType: customer_usage_type,
        ExemptionNo: order.user.try(:exemption_number),
        Client:  AVATAX_CLIENT_VERSION || 'SpreeExtV3.0',
        DocCode: order.number.to_s + '.' + refund_id.to_s,

        ReferenceCode: order.number,
        DetailLevel: 'Tax',
        Commit: commit,
        DocType: invoice_detail ? invoice_detail : 'ReturnOrder',
        Addresses: avatax_address.addresses,
        Lines: avatax_line.lines
      }

      gettaxes[:TaxOverride] = taxoverride

      AVALARA_TRANSACTION_LOGGER.debug gettaxes

      mytax = TaxSvc.new

      AVALARA_TRANSACTION_LOGGER.info '********** hitting the api'

      get_tax_result = mytax.get_tax(gettaxes)

      AVALARA_TRANSACTION_LOGGER.debug get_tax_result

      if get_tax_result == 'error in Tax'
        @myrtntax = { TotalTax: '0.00' }
      else
        if get_tax_result['ResultCode'] == 'Success'
          AVALARA_TRANSACTION_LOGGER.info 'total tax'
          AVALARA_TRANSACTION_LOGGER.debug get_tax_result['TotalTax'].to_s
          @myrtntax = get_tax_result
        end
      end
      @myrtntax
    end

    def customer_usage_type
      order.user ? order.user.avalara_entity_use_code.try(:use_code) : ''
    end

    def customer_code
      order.user ? order.user.id : 'Guest'
    end

    def document_committing_enabled?
      Spree::Config.avatax_document_commit
    end

    def tax_calculation_enabled?
      Spree::Config.avatax_tax_calculation
    end
  end
end
