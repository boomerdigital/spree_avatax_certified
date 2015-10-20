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
end
