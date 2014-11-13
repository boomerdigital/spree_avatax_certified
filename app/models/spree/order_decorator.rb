require 'logger'

Spree::Order.class_eval do

  @@avatax_logger = AvataxHelper::AvataxLog.new("avalara_order", "order class", 'start order processing')

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
    @@avatax_logger.debug 'avalara lookup'
    create_avalara_transaction
    :lookup_avatax
  end

  def avalara_capture
    @@avatax_logger.debug 'avalara capture'

    begin
      create_avalara_transaction
      self.adjustments.destroy_all
      @rtn_tax = self.avalara_transaction.commit_avatax(line_items, self)

      @@avatax_logger.info 'tax amount'
      @@avatax_logger.debug @rtn_tax

      self.adjustments.create do |adjustment|
        adjustment.source = self
        adjustment.label = 'Tax'
        adjustment.mandatory = true
        adjustment.eligible = true
        adjustment.amount = @rtn_tax
      end
    rescue => e
      @@avatax_logger.debug e
      @@avatax_logger.debug 'error in a avalara capture'
    end
  end

  def avalara_capture_finalize
    @@avatax_logger.debug 'avalara capture finalize'
    begin
      create_avalara_transaction

      self.adjustments.destroy_all
      @sat = Spree::AvalaraTransaction.new
      @rtn_tax = @sat.commit_avatax(line_items, self)

      @@avatax_logger.info 'tax amount'
      @@avatax_logger.debug @rtn_tax

      self.adjustments.create do |adjustment|
        adjustment.source = self
        adjustment.label = 'Tax'
        adjustment.mandatory = true
        adjustment.eligible = true
        adjustment.amount = @rtn_tax
      end
    rescue => e
      @@avatax_logger.debug e
      @@avatax_logger.debug 'error in a avalara capture finalize'
    end
  end
end
