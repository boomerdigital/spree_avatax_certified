Spree::Order.class_eval do
  has_one :avalara_transaction, dependent: :destroy

  after_save :avalara_capture_finalize, if: :payment_state_changed_to_paid?
  after_save :cancel_avalara, if: :payment_state_changed_to_void?

  self.state_machine.before_transition :to => :canceled,
                                      :do => :cancel_avalara,
                                      :if => :avalara_tax_enabled?
  self.state_machine.before_transition :to => :delivery,
                                      :do => :validate_ship_address,
                                      :if => :address_validation_enabled?
  def avalara_tax_enabled?
    Spree::Config.avatax_tax_calculation
  end

  def payment_state_changed_to_paid?
    saved_change_to_payment_state?(to: 'paid')
  end

  def payment_state_changed_to_void?
    saved_change_to_payment_state?(to: 'void')
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

    return response if response['ResultCode'] == 'Success'

    messages = response['Messages'].each do |message|
      errors.add(:address_validation_failure, message['Summary'])
    end
   return false
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
