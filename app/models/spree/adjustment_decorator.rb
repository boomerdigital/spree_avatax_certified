Spree::Adjustment.class_eval do
  scope :not_tax, -> { where.not(source_type: 'Spree::TaxRate') }

  def avatax_cache_key
    key = ['Spree::Adjustment']
    key << id
    key << amount
    key.join('-')
  end
end
