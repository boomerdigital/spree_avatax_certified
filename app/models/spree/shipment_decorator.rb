Spree::Shipment.class_eval do
  def avatax_cache_key
    key = ['Spree::Shipment']
    key << id
    key << cost
    key << stock_location.cache_key
    key << promo_total
    key.join('-')
  end

  def avatax_line_code
    'FR'
  end
end
