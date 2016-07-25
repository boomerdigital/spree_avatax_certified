require 'logger'
REFUND_LOGGER = AvataxHelper::AvataxLog.new('refund', 'refund class')

Spree::Refund.class_eval do
  REFUND_LOGGER.info('start refund processing')

  has_one :avalara_transaction
  after_create :avalara_capture_finalize, if: :avalara_eligible?

  def avalara_eligible?
    Spree::Config.avatax_iseligible
  end

  def avalara_capture
    REFUND_LOGGER.debug 'avalara capture refund avalara_capture'
    begin
      @rtn_tax = payment.order.avalara_transaction.commit_avatax('ReturnOrder', self)

      REFUND_LOGGER.info 'tax amount'
      REFUND_LOGGER.debug @rtn_tax
      @rtn_tax
    rescue => e
      REFUND_LOGGER.debug e
      REFUND_LOGGER.debug 'error in avalara capture refund'
    end
  end

  def avalara_capture_finalize
    REFUND_LOGGER.debug 'avalara capture refund avalara_capture_finalize'
    begin
      @rtn_tax = payment.order.avalara_transaction.commit_avatax_final('ReturnInvoice', self)

      REFUND_LOGGER.info 'tax amount'
      REFUND_LOGGER.debug @rtn_tax
      @rtn_tax
    rescue => e
      REFUND_LOGGER.debug e
      REFUND_LOGGER.debug 'error in avalara capture refund finalize'
    end
  end
end
