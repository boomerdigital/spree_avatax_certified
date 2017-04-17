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
    logger.info "Start avalara_capture for order #{number}"

    create_avalara_transaction if avalara_transaction.nil?

    avalara_transaction.commit_avatax('SalesOrder')
  end

  def avalara_capture_finalize
    logger.info "Start avalara_capture_finalize for order #{number}"

    create_avalara_transaction if avalara_transaction.nil?

    avalara_transaction.commit_avatax_final('SalesInvoice')
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
    @logger ||= SpreeAvataxCertified::AvataxLog.new('Spree::Order class', 'Start order processing')
  end
end
