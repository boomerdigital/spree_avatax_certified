module Spree::StockLocationDecorator
  def self.prepended(base)
    base.include ToAvataxHash
  end

  ::Spree::StockLocation.prepend self
end
