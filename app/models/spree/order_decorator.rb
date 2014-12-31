require 'logger'
require_relative 'avalara_transaction'


Spree::Order.class_eval do
  logger = Logger.new('log/avalara_order.txt', 'weekly')

  #logger.level = :debug
  logger.progname = 'order class'
  logger.info 'start order processing'

  has_one :avalara_transaction, :dependent => :destroy


  self.state_machine.after_transition :to => :payment,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :canceled,
                                      :do => :avalara_void,
                                      :if => :avalara_eligible

  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

  def avalara_lookup
    logger = Logger.new('log/avalara_order.txt', 'weekly')
    logger.progname = 'order class'
    logger.debug 'avalara lookup'
    create_avalara_transaction
    :lookup_avatax
  end

  def avalara_capture
    logger = Logger.new('log/avalara_order.txt', 'weekly')
    logger.progname = 'order class'
    logger.debug 'avalara capture'
    begin
      create_avalara_transaction

      self.adjustments.avalara_tax.destroy_all
      sat = Spree::AvalaraTransaction.new
      rtn_tax = sat.commit_avatax(line_items, self)
      logger.info 'tax amount'
      logger.debug rtn_tax

      adjustments.create do |adjustment|
        adjustment.source = self
        adjustment.originator = avalara_transaction
        adjustment.label = 'Tax'
        adjustment.mandatory = true
        adjustment.eligible = true
        adjustment.amount = rtn_tax
      end
    rescue => e
      logger.debug e
      logger.debug 'error in a avalara capture'
    end
  end

  def avalara_void
    adjustments.avalara_tax.each do |adjustment|
      adjustment.originator.update_adjustment(adjustment, adjustment.source)
    end
  end

  def create_tax_charge!
    #Disable Spree's Tax mechanism
  end
end
