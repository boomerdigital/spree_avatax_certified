module Spree::AdjustmentDecorator
  def self.prepended(base)
    base.scope :not_tax, -> { where.not(source_type: 'Spree::TaxRate') }
  end

  def avatax_cache_key
    key = ['Spree::Adjustment']
    key << id
    key << amount
    key.join('-')
  end

  Spree::Adjustment.prepend self
end
