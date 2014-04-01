require 'logger'
require_relative 'avalara_transaction'



Spree::Order.class_eval do


  logger = Logger.new('avalara_order.txt', 'weekly')

  #logger.level = :debug
  logger.progname = 'order class'
  logger.info 'start order processing'

  has_one :avalara_transaction, :dependent => :destroy


  self.state_machine.after_transition :to => :payment,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  #self.state_machine.after_transition :to => :complete,
  #                                    :do => :avalara_capture,
  #                                    :if => :avalara_eligible
  if (:payment or :complete) and :avalara_eligible
    #:avalara_lookup
    :avalara_capture
  end



  # the complete is not running
  # after save call add payment greater change to line item
  # if payment? or if compelte?


  def avalara_eligible
   #temporarily return true
    iseligible = Spree::Config.avatax_iseligible
    if iseligible
      true
    #else
     # false
    end
  end


  def avalara_lookup
    logger = Logger.new('avalara_order.txt', 'weekly')
    logger.progname = 'order class'
    logger.debug 'avalara lookup'
    create_avalara_transaction
    :lookup_avatax

  end
#if use originator need to code update adjustment
#check here for update or new
  # should destroy when recalc occurs
  def avalara_capture
    logger = Logger.new('avalara_order.txt', 'weekly')
    logger.progname = 'order class'
    logger.debug 'avalara capture'
    begin
    create_avalara_transaction
    sat = Spree::AvalaraTransaction.new
    rtn_tax = sat.commit_avatax(line_items, self)
    adjustments.create do |adjustment|
      adjustment.source = self
      #adjustment.originator = avalara_transaction
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
