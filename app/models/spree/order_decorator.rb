require 'logger'

Spree::Order.class_eval do

  has_one :avalara_transaction, dependent: :destroy
  self.state_machine.after_transition :to => :payment,
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible

  self.state_machine.after_transition :to => :complete,
                                      :do => :avalara_capture_finalize,
                                      :if => :avalara_eligible
 self.state_machine.after_transition :to => :canceled,
                                      :do => :cancel_status,
                                      :if => :avalara_eligible

  def avalara_eligible
    Spree::Config.avatax_iseligible
  end

  def avalara_lookup
    logger.debug 'avalara lookup'
    create_avalara_transaction
    :lookup_avatax
  end

  def cancel_status
    self.avalara_transaction.check_status(self)
  end

  def avalara_capture
    logger.debug 'avalara capture'

    begin
      create_avalara_transaction
      self.adjustments.avalara_tax.destroy_all
      @rtn_tax = self.avalara_transaction.commit_avatax(line_items, self)

      logger.info 'tax amount'
      logger.debug @rtn_tax

      unless @rtn_tax == "0"
        adjustments.create do |adjustment|
          adjustment.source = avalara_transaction
          adjustment.label = 'Tax'
          adjustment.mandatory = true
          adjustment.eligible = true
          adjustment.amount = @rtn_tax
          adjustment.order = self
        end
        self.reload.update!
        adjustments.avalara_tax.last
      end
    rescue => e
      logger.debug e
      logger.debug 'error in a avalara capture'
    end
  end

  def avalara_capture_finalize
    logger.debug 'avalara capture finalize'
    begin
      create_avalara_transaction

      self.adjustments.avalara_tax.destroy_all
      @rtn_tax = self.avalara_transaction.commit_avatax_final(line_items, self)

      logger.info 'tax amount'
      logger.debug @rtn_tax

      unless @rtn_tax == "0"
        adjustments.create do |adjustment|
          adjustment.source = avalara_transaction
          adjustment.label = 'Tax'
          adjustment.mandatory = true
          adjustment.eligible = true
          adjustment.amount = @rtn_tax
          adjustment.order = self
        end
        self.reload.update!
        adjustments.avalara_tax.last
      end
    rescue => e
      logger.debug e
      logger.debug 'error in a avalara capture finalize'
    end
  end

  def display_avalara_tax_total
    avatax_tax = BigDecimal.new("0")
    self.adjustments.avalara_tax.each do |tax|
      avatax_tax += tax.amount
    end
    Spree::Money.new(avatax_tax, { currency: currency })
  end

  private
  def logger
    @logger ||= AvataxHelper::AvataxLog.new("avalara_order", "order class", 'start order processing')
  end
end