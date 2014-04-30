require 'logger'
require_relative 'avalara_transaction'

AVALARA_ORDER_LOG = Rails.root.join('log','avalara_order.txt')

Spree::Order.class_eval do


  logger = Logger.new(AVALARA_ORDER_LOG, 'weekly')

  #logger.level = :debug
  logger.progname = 'order class'
  logger.info 'start order processing'

  has_one :avalara_transaction, :dependent => :destroy


  self.state_machine.after_transition :to => :payment,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :complete,
                                      :do => :avalara_capture,
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
    logger = Logger.new(AVALARA_ORDER_LOG, 'weekly')
    logger.progname = 'order class'
    logger.debug 'avalara lookup'
    create_avalara_transaction
    :lookup_avatax

  end

  def avalara_capture

    logger = Logger.new(AVALARA_ORDER_LOG, 'weekly')
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

  def avalara_capture_finalize

    logger = Logger.new(AVALARA_ORDER_LOG, 'weekly')
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






end
