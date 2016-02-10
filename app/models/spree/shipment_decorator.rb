Spree::Shipment.class_eval do

  def avatax_cache_key
    key = ['Spree::Shipment']
    key << self.id
    key << self.cost
    key << self.stock_location.cache_key
    key << self.promo_total
    key.join('-')
  end

  def avatax_line_code
    'FR'
  end

  def shipping_method_tax_code
    tax_code = shipping_method.tax_category.try(:description)
    if tax_code.nil? || tax_code.empty?
      'FR000000'
    else
      tax_code
    end
  end
end
