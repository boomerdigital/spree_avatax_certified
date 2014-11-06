require 'logger'

Spree::Order.class_eval do

  has_one :avalara_transaction, dependent: :destroy
  self.state_machine.after_transition :to => :payment,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :complete,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

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

      self.adjustments.create do |adjustment|
        adjustment.source = self
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
      @rtn_tax = @sat.commit_avatax(line_items, self)

      logger.info 'tax amount'
      logger.debug rtn_tax

      self.adjustments.create do |adjustment|
        adjustment.source = self
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
    AvataxHelper::AvataxLog.new("avalara_order", "order class", 'start order processing')
  end
end
