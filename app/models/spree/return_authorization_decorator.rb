require 'logger'
RETURN_AUTHORIZATION_LOGGER = AvataxHelper::AvataxLog.new("return_authorization", "return_authorization class")

Spree::ReturnAuthorization.class_eval do
  RETURN_AUTHORIZATION_LOGGER.info('start ReturnAuthorization processing')

  has_one :avalara_transaction, dependent: :destroy
  after_save :assign_avalara_transaction
  self.state_machine.after_transition :to => :received,
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

      create_avalara_transaction_return_auth

      order.all_adjustments.avalara_tax.destroy_all

      @rtn_tax = self.avalara_transaction.commit_avatax(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"), "ReturnOrder")

      RETURN_AUTHORIZATION_LOGGER.info 'tax amount'
      RETURN_AUTHORIZATION_LOGGER.debug @rtn_tax

      Spree::Adjustment.create(amount: @rtn_tax, label: 'Tax',adjustable: order, source: self.avalara_transaction, mandatory: true, eligible: true, order: order)
      order.reload.update!
      order.all_adjustments.avalara_tax
    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end

  def avalara_capture_finalize
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara capture return_authorization avalara_capture_finalize'

    begin
      create_avalara_transaction_return_auth

      order.all_adjustments.avalara_tax.destroy_all

      @rtn_tax = self.avalara_transaction.commit_avatax_final(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"), "ReturnInvoice")

      RETURN_AUTHORIZATION_LOGGER.info 'tax amount'
      RETURN_AUTHORIZATION_LOGGER.debug @rtn_tax

      Spree::Adjustment.create(amount: @rtn_tax, label: 'Tax',adjustable: order, source: self.avalara_transaction, mandatory: true, eligible: true, order: order)
      order.reload.update!
      order.all_adjustments.avalara_tax
    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end

  def create_avalara_transaction_return_auth
    Spree::AvalaraTransaction.create(order_id: order.id, return_authorization_id: self.id)
  end

  def assign_avalara_transaction
    if avalara_eligible && self.avalara_transaction.nil?
      avalara_capture
    end
  end
end
