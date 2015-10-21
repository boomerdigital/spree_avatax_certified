class MyConfigPreferences
  def self.set_preferences
    Spree::Config.avatax_address_validation_enabled_countries = ["United States of America", "Canada"]
    Spree::Config.avatax_iseligible = true
    Spree::Config.avatax_company_code = ENV['AVATAX_COMPANY_CODE']
    Spree::Config.avatax_endpoint = ENV['AVATAX_ENDPOINT']
    Spree::Config.avatax_account = ENV['AVATAX_ACCOUNT']
    Spree::Config.avatax_license_key = ENV['AVATAX_LICENSE_KEY']
    Spree::Config.avatax_log = true
    Spree::Config.avatax_address_validation = false
    Spree::Config.avatax_document_commit = true
    Spree::Config.avatax_tax_calculation = true
    Spree::Config.avatax_origin = "{\"Address1\":\"915 S Jackson St\",\"Address2\":\"\",\"City\":\"Montgomery\",\"Region\":\"Alabama\",\"Zip5\":\"36104\",\"Zip4\":\"\",\"Country\":\"US\"}"
  end
end
