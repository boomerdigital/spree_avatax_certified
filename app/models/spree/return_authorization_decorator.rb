require 'logger'

Spree::ReturnAuthorization.class_eval do
  RETURN_AUTHORIZATION_LOGGER = AvataxHelper::AvataxLog.new("return_authorization", "return_authorization class")
  RETURN_AUTHORIZATION_LOGGER.info('start ReturnAuthorization processing')

  has_one :avalara_transaction, dependent: :destroy
  self.state_machine.after_transition :to => :authorized,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :received,
                                      :do => :avalara_capture_finalize,
                                      :if => :avalara_eligible
  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

  def avalara_lookup
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara lookup return_authorization'
    :lookup_avatax
  end

  def avalara_capture
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara capture return_authorization'

    begin
      create_avalara_transaction

      order.adjustments.avalara_tax.destroy_all
      @rtn_tax = order.avalara_transaction.commit_avatax(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"))
      RETURN_AUTHORIZATION_LOGGER.info 'tax amount'
      RETURN_AUTHORIZATION_LOGGER.debug @rtn_tax
      Spree::Adjustment.create(amount: @rtn_tax, label: 'Tax',adjustable: order, source: order, mandatory: true, eligible: true)

    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end

  def avalara_capture_finalize
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara capture return_authorization avalara_capture_finalize'

    begin
      create_avalara_transaction

      order.adjustments.destroy_all
      @rtn_tax = order.avalara_transaction.commit_avatax_final(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"))
      RETURN_AUTHORIZATION_LOGGER.info 'tax amount'
      RETURN_AUTHORIZATION_LOGGER.debug @rtn_tax
      Spree::Adjustment.create(amount: @rtn_tax, label: 'Tax',adjustable: order, source: order, mandatory: true, eligible: true)

    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end
end
