Spree::Refund.class_eval do
  has_one :avalara_transaction
  after_create :avalara_capture_finalize, if: :avalara_tax_enabled?

  def avalara_tax_enabled?
    Spree::Config.avatax_tax_calculation
  end

  def avalara_capture
    logger.info "Start Spree::Refund#avalara_capture for order #{payment.order.number}"

    begin
      payment.order.avalara_transaction.commit_avatax('ReturnOrder', self)
    rescue => e
      logger.error e, 'Refund Capture Error'
      'error in avalara capture refund'
    end
  end

  def avalara_capture_finalize
    logger.info "Start Spree::Refund#avalara_capture_finalize for order #{payment.order.number}"

    begin
      payment.order.avalara_transaction.commit_avatax_final('ReturnInvoice', self)
    rescue => e
      logger.error e, 'Refund Capture Finalize Error'
      'error in avalara capture finalize refund'
    end
  end

  private

  def logger
    @logger ||= SpreeAvataxCertified::AvataxLog.new('Spree::Refund class', 'Start refund capture')
  end
end
