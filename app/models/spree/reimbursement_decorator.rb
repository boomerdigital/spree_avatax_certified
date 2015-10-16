require 'logger'
REIMBURSEMENT_LOGGER = AvataxHelper::AvataxLog.new('reimbursement', 'reimbursement class')

Spree::Reimbursement.class_eval do
  REIMBURSEMENT_LOGGER.info('start Reimbursement processing')

  has_one :avalara_transaction
  after_save :assign_avalara_transaction, if: :order_has_avalara_transaction?

  def perform!
    reimbursement_tax_calculator.call(self)
    reload
    update!(total: calculated_total)

    reimbursement_performer.perform(self)

    if unpaid_amount_within_tolerance?
      self.avalara_capture_finalize
      reimbursed!

      reimbursement_success_hooks.each { |h| h.call self }
      send_reimbursement_email
    else
      errored!
      reimbursement_failure_hooks.each { |h| h.call self }
      raise IncompleteReimbursementError, Spree.t('validation.unpaid_amount_not_zero', amount: unpaid_amount)
    end
  end

  def simulate
    reimbursement_simulator_tax_calculator.call(self)
    reload
    update!(total: calculated_total)

    self.avalara_capture
    reimbursement_performer.simulate(self)
  end

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
      @rtn_tax = Spree::AvalaraTransaction.find_by_reimbursement_id(self.id).commit_avatax(order.line_items, order, order.number.to_s + '.' + self.id.to_s, order.completed_at.strftime('%F'), 'ReturnInvoice')

      REIMBURSEMENT_LOGGER.info 'tax amount'
      REIMBURSEMENT_LOGGER.debug @rtn_tax

      @rtn_tax
    rescue => e
      REIMBURSEMENT_LOGGER.debug e
      REIMBURSEMENT_LOGGER.debug 'error in avalara capture reimbursement'
    end
  end

  def avalara_capture_finalize
    REIMBURSEMENT_LOGGER.debug 'avalara capture reimbursement avalara_capture_finalize'
    begin

      @rtn_tax = self.avalara_transaction.commit_avatax_final(order.line_items, order, order.number.to_s + '.' + self.id.to_s, order.completed_at.strftime('%F'), 'ReturnInvoice')

      REIMBURSEMENT_LOGGER.info 'tax amount'
      REIMBURSEMENT_LOGGER.debug @rtn_tax

      @rtn_tax
    rescue => e
      REIMBURSEMENT_LOGGER.debug e
      REIMBURSEMENT_LOGGER.debug 'error in avalara capture reimbursement'
    end
  end

  def create_avalara_transaction_return_auth
    Spree::AvalaraTransaction.create(order_id: order.id, reimbursement_id: self.id)
  end

  def assign_avalara_transaction
    if avalara_eligible
      if order.avalara_transaction.reimbursement_id.nil?
        Spree::AvalaraTransaction.find_by_order_id(order.id).update_attributes(reimbursement_id: self.id)
      end
    end
  end

  def order_has_avalara_transaction?
    order.avalara_transaction.nil? ? false : true
  end
end
