Spree::Order.class_eval do



  has_one :tax_cloud_transaction


  self.state_machine.after_transition :to => 'payment',
                                      :do => :avalara_lookup,
                                      :if => :avalara_eligible?

  self.state_machine.after_transition :to => 'complete',
                                      :do => :avalara_lookup,
                                      :if => :avalara_eligible?


  def tax_cloud_eligible?

    ship_address.try(:state_id?)

  end


  # Finalizes an in progress order after checkout is complete.
  # Called after transition to complete state when payments will have been processed
  def finalize!
    touch :completed_at
    Spree::InventoryUnit.assign_opening_inventory(self)
    # lock any optional adjustments (coupon promotions, etc.)
    adjustments.optional.each { |adjustment| adjustment.update_column('locked', true) }
    deliver_order_confirmation_email
    response=post_order_to_avalara(true)

    self.state_changes.create({
                                  :previous_state => 'cart',
                                  :next_state     => 'complete',
                                  :name           => 'order' ,
                                  :user_id        => self.user_id
                              }, :without_protection => true)
  end


  def update_adjustments
    #create_tax_charge!
    self.adjustments.reload.each { |adjustment| adjustment.update!(self) }
  end


  def create_tax_charge!
    self.clear_adjustments!
    #create tax estimate and required adjustments.
    #commit =false, do not create transaction on Avalara side.

    #only relevant if we have a billing address
    if self.billing_address != nil and self.line_items.length > 0
      response=post_order_to_avalara
      create_avalara_tax_adjustments(response)
    end
  end


  private
  def post_order_to_avalara(commit=false)
    #Create array for line items
    tax_line_items=Array.new

    self.line_items.each_with_index do |line_item, i|
      line_item_total=line_item.price*line_item.quantity
      line=Avalara::Request::Line.new(:line_no => i, :origin_code => 1, :destination_code => 1, :qty => line_item.quantity, :amount => line_item_total)
      tax_line_items<<line
    end

    #Billing Address
    address=Avalara::Request::Address.new(:address_code => 1)
    address.line_1=self.billing_address.address1
    address.postal_code=self.billing_address.zipcode

    addresses=Array.new
    addresses<<address

    invoice=Avalara::Request::Invoice.new
    invoice.doc_code=self.number
    invoice.customer_code="TheRealReal"
    invoice.addresses=addresses
    invoice.lines=tax_line_items
    #A record is created when commit is true + doc_type is SalesInvoice
    if commit
      invoice.commit=true
      invoice.doc_type="SalesInvoice"
    end
    response=Avalara.get_tax(invoice)
    response
  end


  #def create_avalara_tax_adjustments(tax_lines)
  #  puts "TAX LINE"
  #  #Spree::TaxRate.adjust(self)
  #  tax_lines.each { |tax_line|
  #    puts tax_line.tax_details.each { |tax_detail|
  #      self.adjustments.create({:amount => tax_detail.tax,
  #                               :source => self,
  #                               :originator => Spree::TaxRate.first,
  #                               :locked => true,
  #                               :label => tax_detail.tax_name}, :without_protection => true)
  #    }
  #  }
  #end


  def create_avalara_tax_adjustments(response)
    puts "Creating tax adjustment"
    #Spree::TaxRate.adjust(self)
    self.adjustments.create({:amount => response.total_tax,
                             :source => self,
                             :originator => Spree::TaxRate.first,
                             :locked => true,
                             :label => "Sales Tax"}, :without_protection => true)
  end


end
