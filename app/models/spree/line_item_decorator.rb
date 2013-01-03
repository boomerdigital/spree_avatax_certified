Spree::LineItem.class_eval do




  def update_order
    order.create_tax_charge!
    order.update!
  end


end