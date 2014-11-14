require 'logger'
AVALARA_ORDER_LOGGER = AvataxHelper::AvataxLog.new("avalara_order", "order class", 'start order processing')

Spree::Order.class_eval do

  has_one :avalara_transaction, dependent: :destroy
  self.state_machine.after_transition :to => :payment,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :complete,
                                      :do => :avalara_capture_finalize,
                                      :if => :avalara_eligible

  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

  def avalara_lookup
    AVALARA_ORDER_LOGGER.debug 'avalara lookup'
    create_avalara_transaction
    :lookup_avatax
  end

  def avalara_capture
    AVALARA_ORDER_LOGGER.debug 'avalara capture'

    begin
      create_avalara_transaction
      self.adjustments.avalara_tax.destroy_all
      @rtn_tax = self.avalara_transaction.commit_avatax(line_items, self)

      AVALARA_ORDER_LOGGER.info 'tax amount'
      AVALARA_ORDER_LOGGER.debug @rtn_tax

      adjustments.create do |adjustment|
        adjustment.source = avalara_transaction
        adjustment.label = 'Tax'
        adjustment.mandatory = true
        adjustment.eligible = true
        adjustment.amount = @rtn_tax
      end
    rescue => e
      AVALARA_ORDER_LOGGER.debug e
      AVALARA_ORDER_LOGGER.debug 'error in a avalara capture'
    end
  end

  def avalara_capture_finalize
    AVALARA_ORDER_LOGGER.debug 'avalara capture finalize'
    begin
      create_avalara_transaction

      self.adjustments.avalara_tax.destroy_all
      @rtn_tax = self.avalara_transaction.commit_avatax_final(line_items, self)

      AVALARA_ORDER_LOGGER.info 'tax amount'
      AVALARA_ORDER_LOGGER.debug @rtn_tax

      adjustments.create do |adjustment|
        adjustment.source = avalara_transaction
        adjustment.label = 'Tax'
        adjustment.mandatory = true
        adjustment.eligible = true
        adjustment.amount = @rtn_tax
      end
    rescue => e
      AVALARA_ORDER_LOGGER.debug e
      AVALARA_ORDER_LOGGER.debug 'error in a avalara capture finalize'
    end
  end
end
