require 'logger'

Spree::Order.class_eval do
  include Spree::Avalara

  logger.info 'start order processing'

  self.state_machine.after_transition :to => :payment,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :complete,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  def avalara_lookup
    logger.debug 'avalara lookup'
    create_avalara_transaction
    :lookup_avatax
  end

  def avalara_capture
    logger.debug 'avalara capture'
    begin
      create_avalara_transaction

      self.adjustments.destroy_all
      @sat = Spree::AvalaraTransaction.new
      @rtn_tax = @sat.commit_avatax(line_items, self)

      logger.info 'tax amount'
      logger.debug @rtn_tax

      adjustments.create do |adjustment|
        adjustment.source = self
        # adjustment.originator = avalara_transaction
        adjustment.label = 'Tax'
        adjustment.mandatory = true
        adjustment.eligible = true
        adjustment.amount = @rtn_tax
      end
    rescue => e
      logger.debug e
      logger.debug 'error in a avalara capture'
    end
  end

  def avalara_capture_finalize
    logger.debug 'avalara capture'
    begin
      create_avalara_transaction

      self.adjustments.destroy_all
      @sat = Spree::AvalaraTransaction.new
      @rtn_tax = sat.commit_avatax(line_items, self)

      logger.info 'tax amount'
      logger.debug rtn_tax

      adjustments.create do |adjustment|
        adjustment.source = self
        # adjustment.originator = avalara_transaction
        adjustment.label = 'Tax'
        adjustment.mandatory = true
        adjustment.eligible = true
        adjustment.amount = @rtn_tax
      end
    rescue => e
      logger.debug e
      logger.debug 'error in a avalara capture'
    end
  end

  private

  def logger
    @logger ||= Logger.new('log/avalara_order.txt', 'weekly')
    @logger.progname = 'order class'
    @logger
  end
end
