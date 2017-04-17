Spree::Address.class_eval do
  def validation_enabled?
    Spree::Config.avatax_address_validation && country_validation_enabled?
  end

  def country_validation_enabled?
    Spree::Address.validation_enabled_countries.include?(country.try(:name))
  end

  def self.validation_enabled_countries
    Spree::Config.avatax_address_validation_enabled_countries
  end
end
