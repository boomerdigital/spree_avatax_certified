require 'logger'

Spree::Order.class_eval do
  has_one :avalara_transaction, dependent: :destroy

  self.state_machine.before_transition :to => :canceled,
                                      :do => :cancel_avalara,
                                      :if => :avalara_tax_enabled?

  def avalara_tax_enabled?
    Spree::Config.avatax_tax_calculation
  end

  def cancel_avalara
    return nil unless avalara_transaction.present?
    avalara_transaction.cancel_order
  end

  def avalara_capture
    logger.debug 'avalara capture'
    create_avalara_transaction if avalara_transaction.nil?

    @rtn_tax = avalara_transaction.commit_avatax('SalesOrder')

    logger.info_and_debug('tax amount', @rtn_tax)
    @rtn_tax
  end

  def avalara_capture_finalize
    logger.debug 'avalara capture finalize'
    create_avalara_transaction if avalara_transaction.nil?

    @rtn_tax = avalara_transaction.commit_avatax_final('SalesInvoice')

    logger.info_and_debug('tax amount', @rtn_tax)
    @rtn_tax
  end

  def avatax_cache_key
    key = ['Spree::Order']
    key << number
    key << promo_total
    key.join('-')
  end

  def customer_usage_type
    user ? user.avalara_entity_use_code.try(:use_code) : ''
  end

  # Bringing this over since it isn't in 2.4 or 3.0
  def update_with_updater!
    updater.update
  end

  private

  def logger
    @logger ||= AvataxHelper::AvataxLog.new('avalara_order', 'order class', 'start order processing')
  end
end
