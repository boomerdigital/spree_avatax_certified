require 'logger'
require_relative 'avalara_transaction'
Spree::ReturnAuthorization.class_eval do
  has_one :avalara_transaction, :dependent => :destroy
  logger = Logger.new('log/return_authorization.txt', 'weekly')
  logger.progname = 'ReturnAuthorization class'
  logger.info 'start ReturnAuthorization processing'

  self.state_machine.after_transition :to => :authorized,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :received,
                                      :do => :avalara_capture_finalize,
                                      :if => :avalara_eligible

  def avalara_eligible
    iseligible = Spree::Config.avatax_iseligible
    if iseligible
      true
    else
      false
    end
  end

  def avalara_lookup
    logger = Logger.new('log/return_authorization.txt', 'weekly')
    logger.progname = 'return_authorization class'
    logger.debug 'avalara lookup return_authorization'

    :lookup_avatax

  end

  def avalara_capture

    logger = Logger.new('log/return_authorization.txt', 'weekly')
    logger.progname = 'return_authorization class'
    logger.debug 'avalara capture return_authorization'
    begin
      create_avalara_transaction

      order.adjustments.avalara_tax.destroy_all
      sat = Spree::AvalaraTransaction.new
      rtn_tax = sat.commit_avatax(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"))
      logger.info 'tax amount'
      logger.debug rtn_tax
      Spree::Adjustment.create(amount: rtn_tax, label: 'Tax',adjustable: order, source: order, originator: avalara_transaction, mandatory: true, eligible: true)

    rescue => e
      logger.debug e
      logger.debug 'error in a avalara capture return_authorization'
    end
  end

  def avalara_capture_finalize

    logger = Logger.new('log/return_authorization.txt', 'weekly')
    logger.progname = 'return_authorization class'
    logger.debug 'avalara capture return_authorization avalara_capture_finalize'
    begin
      create_avalara_transaction

      order.adjustments.avalara_tax.destroy_all
      sat = Spree::AvalaraTransaction.new
      rtn_tax = sat.commit_avatax_final(order.line_items, order, order.number.to_s + ":" + self.id.to_s, order.completed_at.strftime("%F"))
      logger.info 'tax amount'
      logger.debug rtn_tax
       Spree::Adjustment.create(amount: rtn_tax, label: 'Tax',adjustable: order, source: order, originator: avalara_transaction, mandatory: true, eligible: true)




    rescue => e
      logger.debug e
      logger.debug 'error in a avalara capture return_authorization'
    end
  end



end
