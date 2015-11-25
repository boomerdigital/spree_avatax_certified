require 'logger'
REFUND_LOGGER = AvataxHelper::AvataxLog.new('refund', 'refund class')

Spree::Refund.class_eval do
  REFUND_LOGGER.info('start refund processing')

  has_one :avalara_transaction
  after_create :avalara_capture_finalize, if: :avalara_eligible?

  def avalara_eligible?
    Spree::Config.avatax_iseligible
  end

  def avalara_capture_finalize
    REFUND_LOGGER.debug 'avalara capture refund avalara_capture_finalize'
    begin
      avalara_transaction_refund = Spree::AvalaraTransaction.find_by_order_id(self.payment.order.id)

      @rtn_tax = avalara_transaction_refund.commit_avatax_final('ReturnInvoice', self)

      REFUND_LOGGER.info 'tax amount'
      REFUND_LOGGER.debug @rtn_tax
      @rtn_tax
    rescue => e
      REFUND_LOGGER.debug e
      REFUND_LOGGER.debug 'error in avalara capture refund finalize'
    end
  end
end
