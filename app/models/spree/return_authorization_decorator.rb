require 'logger'
RETURN_AUTHORIZATION_LOGGER = AvataxHelper::AvataxLog.new("return_authorization", "return_authorization class")

Spree::ReturnAuthorization.class_eval do
  RETURN_AUTHORIZATION_LOGGER.info('start ReturnAuthorization processing')

  has_one :avalara_transaction, dependent: :destroy
  after_save :assign_avalara_transaction, on: :create
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
      @rtn_tax = Spree::AvalaraTransaction.find_by_return_authorization_id(self.id).commit_avatax(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"), "ReturnInvoice")

      RETURN_AUTHORIZATION_LOGGER.info 'tax amount'
      RETURN_AUTHORIZATION_LOGGER.debug @rtn_tax
    rescue => e
      RETURN_AUTHORIZATION_LOGGER.debug e
      RETURN_AUTHORIZATION_LOGGER.debug 'error in a avalara capture return_authorization'
    end
  end

  def avalara_capture_finalize
    RETURN_AUTHORIZATION_LOGGER.debug 'avalara capture return_authorization avalara_capture_finalize'

    begin
      @rtn_tax = self.avalara_transaction.commit_avatax_final(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"), "ReturnInvoice")

      RETURN_AUTHORIZATION_LOGGER.info 'tax amount'
      RETURN_AUTHORIZATION_LOGGER.debug @rtn_tax
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
      if self.avalara_transaction.nil?
        create_avalara_transaction_return_auth
      else
        Spree::AvalaraTransaction.find_by_return_authorization_id(self.id).update_attributes(order_id: order.id, return_authorization_id: self.id)
      end
    end
  end
end
