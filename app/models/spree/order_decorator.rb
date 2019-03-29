Spree::Order.class_eval do
  has_one :avalara_transaction, dependent: :destroy

  self.state_machine.before_transition :to => :canceled,
                                      :do => :cancel_avalara,
                                      :if => :avalara_tax_enabled?
  self.state_machine.before_transition :to => :delivery,
                                      :do => :validate_ship_address,
                                      :if => :address_validation_enabled?
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

  def address_validation_enabled?
    return false if ship_address.nil?

    ship_address.validation_enabled?
  end

    def validate_ship_address
    avatax_address = SpreeAvataxCertified::Address.new(self)
    response = avatax_address.validate

    return response.result if response.success?
    return response if !Spree::Config.avatax_refuse_checkout_address_validation_error

    response.summary_messages.each do |msg|
      errors.add(:address_validation_failure, msg)
    end

   return false
  end

  # Bringing this over since it isn't in 2.4 or 3.0
  def update_with_updater!
    updater.update
  end

  def can_commit?
    completed? && payments.completed.any?
  end

  private

  def logger
    @logger ||= SpreeAvataxCertified::AvataxLog.new('Spree::Order class', 'Start order processing')
  end
end
