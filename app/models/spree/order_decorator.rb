require_relative 'avalara/spree_avalara_transaction'


Spree::Order.class_eval do



  has_one :tax_cloud_transaction


  self.state_machine.after_transition :to => 'payment',
                                      :do => :avalara_lookup,
                                      :if => :avalara_eligible?

  self.state_machine.after_transition :to => 'complete',
                                      :do => :avalara_capture,
                                      :if => :avalara_eligible?


  def avalara_eligible?
   #temporarily return true
    true
  end


  def avalara_lookup

  end


  def avalara_capture

  end








end
