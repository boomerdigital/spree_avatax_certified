Spree::Payment.class_eval do
  self.state_machine.after_transition to: :completed,
                                      do: :avalara_finalize

  # create validation that makes sure payment captured is of full amount that was sent to avalara if the order has tax

  def avalara_finalize
    order.avalara_capture_finalize if Spree::Config.avatax_iseligible
  end
end
