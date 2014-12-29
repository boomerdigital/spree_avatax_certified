require 'logger'
REIMBURSEMENT_LOGGER = AvataxHelper::AvataxLog.new("reimbursement", "reimbursement class")

Spree::Reimbursement.class_eval do
  REIMBURSEMENT_LOGGER.info('start Reimbursement processing')

  has_one :avalara_transaction, dependent: :destroy
  after_save :assign_avalara_transaction

  self.state_machine(:reimbursement_status).after_transition :to => :reimbursed, :do => :avalara_capture_finalize, :if => :avalara_eligible

  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

  def avalara_lookup
    REIMBURSEMENT_LOGGER.debug 'avalara lookup reimbursement'
    create_avalara_transaction_return_auth
    :lookup_avatax
  end

  def avalara_capture
    REIMBURSEMENT_LOGGER.debug 'avalara capture reimbursement'
    begin
      create_avalara_transaction_return_auth

      order.adjustments.avalara_tax.destroy_all

      @rtn_tax = self.avalara_transaction.commit_avatax(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"), "ReturnOrder")

      REIMBURSEMENT_LOGGER.info 'tax amount'
      REIMBURSEMENT_LOGGER.debug @rtn_tax
      Spree::Adjustment.create(amount: @rtn_tax, label: 'Tax',adjustable: order, source: self.avalara_transaction, mandatory: true, eligible: true, order: order)
      order.reload.update!
      order.adjustments.avalara_tax.last
    rescue => e
      REIMBURSEMENT_LOGGER.debug e
      REIMBURSEMENT_LOGGER.debug 'error in a avalara capture reimbursement'
    end
  end

  def avalara_capture_finalize
    REIMBURSEMENT_LOGGER.debug 'avalara capture reimbursement avalara_capture_finalize'

    begin
      create_avalara_transaction_return_auth

      order.adjustments.avalara_tax.destroy_all

      @rtn_tax = self.avalara_transaction.commit_avatax_final(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"), "ReturnInvoice")
      REIMBURSEMENT_LOGGER.info 'tax amount'
      REIMBURSEMENT_LOGGER.debug @rtn_tax
      Spree::Adjustment.create(amount: @rtn_tax, label: 'Tax',adjustable: order, source: self.avalara_transaction, mandatory: true, eligible: true, order: order)

      order.reload.update!
      order.adjustments.avalara_tax.last
    rescue => e
      REIMBURSEMENT_LOGGER.debug e
      REIMBURSEMENT_LOGGER.debug 'error in a avalara capture reimbursement'
    end
  end

  def create_avalara_transaction_return_auth
    Spree::AvalaraTransaction.create(order_id: order.id, reimbursement_id: self.id)
  end

  def assign_avalara_transaction
    if avalara_eligible
      avalara_capture
    end
  end
end
