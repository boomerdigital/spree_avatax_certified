require 'logger'
REFUND_LOGGER = AvataxHelper::AvataxLog.new("refund", "refund class")

Spree::Refund.class_eval do
  REFUND_LOGGER.info('start refund processing')

  has_one :avalara_transaction, dependent: :destroy
  after_save :assign_avalara_transaction, on: :create
  after_save :avalara_capture_finalize, on: :update

  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

  def avalara_lookup
    REIMBURSEMENT_LOGGER.debug 'avalara lookup reimbursement'
    create_avalara_transaction_refund
    :lookup_avatax
  end

  def avalara_capture
    if self.reimbursement_id.nil?
      REFUND_LOGGER.debug 'avalara capture refund'
      begin
        avalara_transaction_refund = Spree::AvalaraTransaction.find_by_refund_id(self.id)
        @rtn_tax = avalara_transaction_refund.commit_avatax(payment.order.line_items, payment.order, payment.order.number.to_s + "." + self.id.to_s, avalara_transaction_refund.order.completed_at.strftime("%F"), "ReturnInvoice")

        REFUND_LOGGER.info 'tax amount'
        REFUND_LOGGER.debug @rtn_tax


        payment.order.reload.update!
        payment.order.all_adjustments.avalara_tax
      rescue => e
        REFUND_LOGGER.debug e
        REFUND_LOGGER.debug 'error in a avalara capture refund'
      end
    end
  end

  def avalara_capture_finalize
    if self.reimbursement_id.nil?
      REFUND_LOGGER.debug 'avalara capture refund avalara_capture_finalize'
      begin
        avalara_transaction_refund = Spree::AvalaraTransaction.find_by_refund_id(self.id)
        @rtn_tax = avalara_transaction_refund.commit_avatax_final(payment.order.line_items, payment.order, payment.order.number.to_s + "." + self.id.to_s, avalara_transaction_refund.order.completed_at.strftime("%F"), "ReturnInvoice")

        REFUND_LOGGER.info 'tax amount'
        REFUND_LOGGER.debug @rtn_tax

        payment.order.reload.update!
        payment.order.all_adjustments.avalara_tax
      rescue => e
        REFUND_LOGGER.debug e
        REFUND_LOGGER.debug 'error in a avalara capture refund finalize'
      end
    end
  end

  def create_avalara_transaction_refund
    Spree::AvalaraTransaction.create(order_id: payment.order.id, refund_id: self.id)
  end

  def assign_avalara_transaction
    if avalara_eligible
      if self.avalara_transaction.nil?
        create_avalara_transaction_refund
      else
        Spree::AvalaraTransaction.find_by_refund_id(self.id).update_attributes(order_id: payment.order.id, refund_id: self.id)
      end
    end
  end

  def pre_tax_amount
    unless payment.order.additional_tax_total.zero?
      tax_amount = tax_percentage * amount
      return amount - tax_amount
    end
  end

  private

  def tax_percentage
    (payment.order.additional_tax_total / payment.order.total).to_f
  end
end