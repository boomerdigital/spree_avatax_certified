module Spree::AddressDecorator
  def self.prepended(base)
    base.include ToAvataxHash
  end

  def validation_enabled?
    Spree::Config.avatax_address_validation && country_validation_enabled?
  end

  def country_validation_enabled?
    validation_enabled_countries.include?(country.try(:name))
  end

  def validation_enabled_countries
    Spree::Config.avatax_address_validation_enabled_countries
  end

  Spree::Address.prepend self
end
