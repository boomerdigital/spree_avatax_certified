require_dependency 'spree/order'

module Spree
  class AvalaraTransaction < ActiveRecord::Base

    belongs_to :order
    belongs_to :reimbursement
    belongs_to :refund
    validates :order, presence: true
    validates :order_id, uniqueness: true

    def lookup_avatax
      post_order_to_avalara(false, 'SalesOrder')
    end

    def commit_avatax(doc_type = nil, refund = nil)
      if tax_calculation_enabled?
        if %w(ReturnInvoice ReturnOrder).include?(doc_type)
          post_return_to_avalara(false, doc_type, refund)
        else
          post_order_to_avalara(false, doc_type)
        end
      else
        { TotalTax: '0.00' }
      end
    end

    def commit_avatax_final(doc_type = nil, refund = nil)
      if document_committing_enabled?
        if tax_calculation_enabled?
          if %w(ReturnInvoice ReturnOrder).include?(doc_type)
            post_return_to_avalara(true, doc_type, refund)
          else
            post_order_to_avalara(true, doc_type)
          end
        else
          { TotalTax: '0.00' }
        end
      else
        logger.info 'Avalara Document Committing Disabled'
        'avalara document committing disabled'
      end
    end

    def cancel_order
      cancel_order_to_avalara('SalesInvoice') if tax_calculation_enabled?
    end

    private

    def cancel_order_to_avalara(doc_type = 'SalesInvoice')
      logger.info "Begin cancel order #{order.number} to avalara..."

      cancel_tax_request = {
        CompanyCode: Spree::Config.avatax_company_code,
        DocType: doc_type,
        DocCode: order.number,
        CancelCode: 'DocVoided'
      }

      mytax = TaxSvc.new
      cancel_tax_result = mytax.cancel_tax(cancel_tax_request)

      logger.debug cancel_tax_result

      if cancel_tax_result == 'Error in Cancel Tax'
        return 'Error in Cancel Tax'
      else
        return cancel_tax_result
      end
    end

    def post_order_to_avalara(commit = false, doc_type = nil)
      logger.info "Begin post order #{order.number} to avalara"

      avatax_address = SpreeAvataxCertified::Address.new(order)
      avatax_line = SpreeAvataxCertified::Line.new(order, doc_type)

      response = avatax_address.validate

      unless response.nil?
        if response['ResultCode'] == 'Success'
          logger.info('Address Validation Success')
        else
          logger.info('Address Validation Failed')
        end
      end

      doc_date = order.completed? ? order.completed_at.strftime('%F') : Date.today.strftime('%F')

      gettaxes = {
        DocCode: order.number,
        DocDate: doc_date,
        Discount: order.adjustments.eligible.promotion.sum(:amount).abs.to_s,
        Commit: commit,
        DocType: doc_type ? doc_type : 'SalesOrder',
        Addresses: avatax_address.addresses,
        Lines: avatax_line.lines
      }.merge(base_tax_hash)

      if !business_id_no.blank?
        gettaxes[:BusinessIdentificationNo] = business_id_no
      end

      mytax = TaxSvc.new
      tax_result = mytax.get_tax(gettaxes)

      return { TotalTax: '0.00' } if tax_result == 'Error in Tax'
      return tax_result if tax_result['ResultCode'] == 'Success'
    end

    def post_return_to_avalara(commit = false, doc_type = nil, refund = nil)
      logger.info "Begin post return order #{order.number} to avalara"

      avatax_address = SpreeAvataxCertified::Address.new(order)
      avatax_line = SpreeAvataxCertified::Line.new(order, doc_type, refund)

      taxoverride = {
        TaxOverrideType: 'TaxDate',
        Reason: 'Return',
        TaxDate: order.completed_at.strftime('%F')
      }

      gettaxes = {
        DocCode: order.number.to_s + '.' + refund.id.to_s,
        DocDate: Date.today.strftime('%F'),
        Commit: commit,
        DocType: doc_type ? doc_type : 'ReturnOrder',
        Addresses: avatax_address.addresses,
        Lines: avatax_line.lines
      }.merge(base_tax_hash)

      if !business_id_no.blank?
        gettaxes[:BusinessIdentificationNo] = business_id_no
      end

      gettaxes[:TaxOverride] = taxoverride

      mytax = TaxSvc.new
      tax_result = mytax.get_tax(gettaxes)

      return { TotalTax: '0.00' } if tax_result == 'Error in Tax'
      return tax_result if tax_result['ResultCode'] == 'Success'
    end

    def base_tax_hash
      {
        CustomerCode: customer_code,
        CompanyCode: Spree::Config.avatax_company_code,
        CustomerUsageType: order.customer_usage_type,
        ExemptionNo: order.user.try(:exemption_number),
        Client:  avatax_client_version,
        ReferenceCode: order.number,
        DetailLevel: 'Tax',
        CurrencyCode: order.currency
      }
    end

    def customer_code
      order.user ? order.user.id : order.email
    end

    def business_id_no
      order.user.try(:vat_id)
    end

    def avatax_client_version
      AVATAX_CLIENT_VERSION || 'a0o33000004FH8l'
    end

    def document_committing_enabled?
      Spree::Config.avatax_document_commit
    end

    def tax_calculation_enabled?
      Spree::Config.avatax_tax_calculation
    end

    def logger
      @logger ||= SpreeAvataxCertified::AvataxLog.new('Spree::AvalaraTransaction class')
    end
  end
end
