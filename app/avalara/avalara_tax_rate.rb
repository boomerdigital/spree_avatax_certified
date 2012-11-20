module Avalara
  class AvalaraTaxRate < Spree::TaxRate
    # Creates necessary tax adjustments for the order.
    after_initialize :init
    def init
      self.name="AvaTax"
    end



    def adjust(order, response)
      order.adjustments.create({:amount => response.total_tax,
                                :source => self,
                                :originator => self,
                                :locked => true,
                                :label => "Sales Tax"}, :without_protection => true)
    end
  end

end