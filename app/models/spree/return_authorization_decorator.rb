require 'logger'
RETURN_AUTHORIZATION_LOGGER = AvataxHelper::AvataxLog.new('return_authorization', 'return_authorization class')

Spree::ReturnAuthorization.class_eval do
  RETURN_AUTHORIZATION_LOGGER.info('start ReturnAuthorization processing')

  has_one :avalara_transaction
  after_save :assign_avalara_transaction, if: :order_has_avalara_transaction?
  self.state_machine.before_transition :to => :received,
                                       :do => :avalara_capture_finalize,
                                       :if => :avalara_eligible

  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

  def avalara_lookup
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara lookup return_authorization'
    create_avalara_transaction_return_auth
    :lookup_avatax
  end

  def avalara_capture
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara capture return_authorization'

    begin
      @rtn_tax = self.avalara_transaction.commit_avatax('ReturnInvoice')

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
      @rtn_tax = self.avalara_transaction.commit_avatax_final('ReturnInvoice')

      RETURN_AUTHORIZATION_LOGGER.info_and_debug('tax amount', @rtn_tax)
      @rtn_tax
    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end

  def create_avalara_transaction_return_auth
    Spree::AvalaraTransaction.create(order_id: order.id, return_authorization_id: self.id)
  end

  def assign_avalara_transaction
    if avalara_eligible
      if order.avalara_transaction.return_authorization_id.nil?
        Spree::AvalaraTransaction.find_by_order_id(order.id).update_attributes(return_authorization_id: self.id)
      end
    end
  end

  def order_has_avalara_transaction?
    order.avalara_transaction.nil? ? false : true
  end
end
