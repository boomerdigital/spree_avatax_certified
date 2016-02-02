require 'logger'

Spree::ReturnAuthorization.class_eval do
  RETURN_AUTHORIZATION_LOGGER = AvataxHelper::AvataxLog.new('return_authorization', 'return_authorization class')
  RETURN_AUTHORIZATION_LOGGER.info('start ReturnAuthorization processing')

  has_one :avalara_transaction
  self.state_machine.before_transition :to => :received,
                                       :do => :avalara_capture_finalize,
                                       :if => :avalara_eligible?

  def avalara_eligible?
    Spree::Config.avatax_iseligible && order_has_avalara_transaction?
  end

  def avalara_lookup
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara lookup return_authorization'
    create_avalara_transaction_return_auth
    :lookup_avatax
  end

  def avalara_capture
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara capture return_authorization'
    begin
      @rtn_tax = order.avalara_transaction.commit_avatax('ReturnOrder', self)

      RETURN_AUTHORIZATION_LOGGER.info_and_debug('tax amount', @rtn_tax)
      @rtn_tax
    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end

  def avalara_capture_finalize
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara capture return_authorization avalara_capture_finalize'
    begin
      @rtn_tax = order.avalara_transaction.commit_avatax_final('ReturnInvoice', self)

      RETURN_AUTHORIZATION_LOGGER.info_and_debug('tax amount', @rtn_tax)

      self.amount = @rtn_tax['TotalAmount'].to_f.abs + @rtn_tax['TotalTax'].to_f.abs unless @rtn_tax[:TotalTax] == '0.00'
      self.save
      @rtn_tax
    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end

  def create_avalara_transaction_return_auth
    Spree::AvalaraTransaction.create(order_id: order.id, return_authorization_id: self.id)
  end

  def order_has_avalara_transaction?
    order.avalara_transaction.nil? ? false : true
  end
end
