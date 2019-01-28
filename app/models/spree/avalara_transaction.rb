require_dependency 'spree/order'

module Spree
  class AvalaraTransaction < Spree::Base

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
        'Avalara Document Committing Disabled'
      end
    end

    def cancel_order
      cancel_order_to_avalara('SalesInvoice') if tax_calculation_enabled?
    end

    private

    def cancel_order_to_avalara(doc_type = 'SalesInvoice')
      logger.info "Begin cancel order #{order.number} to avalara..."

      request = SpreeAvataxCertified::Request::CancelTax.new(order, doc_type: doc_type).generate

      mytax = TaxSvc.new
      mytax.cancel_tax(request).tax_result
    end

    def post_order_to_avalara(commit = false, doc_type = nil)
      logger.info "Begin post order #{order.number} to avalara"

      request = SpreeAvataxCertified::Request::GetTax.new(order, commit: commit, doc_type: doc_type).generate

      mytax = TaxSvc.new
      response = mytax.get_tax(request)

      return { TotalTax: '0.00' } if response.error?
      response.tax_result
    end

    def post_return_to_avalara(commit = false, doc_type = nil, refund = nil)
      logger.info "Begin post return order #{order.number} to avalara"

      request = SpreeAvataxCertified::Request::ReturnTax.new(order, commit: commit, doc_type: doc_type, refund: refund).generate

      mytax = TaxSvc.new
      response = mytax.get_tax(request)

      return { TotalTax: '0.00' } if response.error?
      response.tax_result
    end

    def document_committing_enabled?
      Spree::Config.avatax_document_commit
    end

    def tax_calculation_enabled?
      Spree::Config.avatax_tax_calculation
    end

    private

    def logger
      @logger ||= SpreeAvataxCertified::AvataxLog.new('Spree::AvalaraTransaction class')
    end
  end
end
