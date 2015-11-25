require 'logger'

Spree::Order.class_eval do

  has_one :avalara_transaction, dependent: :destroy

  self.state_machine.before_transition :to => :canceled,
                                      :do => :cancel_avalara,
                                      :if => :avalara_eligible?

  def avalara_eligible?
    Spree::Config.avatax_iseligible
  end

  def cancel_avalara
    return nil unless avalara_transaction.present?
    self.avalara_transaction.cancel_order
  end

  def avalara_capture
    logger.debug 'avalara capture'
    begin
      create_avalara_transaction if avalara_transaction.nil?
      line_items.reload

      @rtn_tax = self.avalara_transaction.commit_avatax('SalesInvoice')

      logger.info_and_debug('tax amount', @rtn_tax)
      @rtn_tax
    rescue => e
      logger.debug e
      logger.debug 'error in avalara capture'
    end
  end

  def avalara_capture_finalize
    logger.debug 'avalara capture finalize'
    begin
      create_avalara_transaction if avalara_transaction.nil?
      line_items.reload
      @rtn_tax = avalara_transaction.commit_avatax_final('SalesInvoice')

      logger.info_and_debug('tax amount', @rtn_tax)
      @rtn_tax
    rescue => e
      logger.debug e
      logger.debug 'error in avalara capture finalize'
    end
  end

  def avatax_cache_key
    key = ['Spree::Order']
    key << self.number
    key << self.promo_total
    key.join('-')
  end

  private

  def logger
    @logger ||= AvataxHelper::AvataxLog.new('avalara_order', 'order class', 'start order processing')
  end
end
