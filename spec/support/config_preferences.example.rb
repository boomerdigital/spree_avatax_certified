class MyConfigPreferences
  def self.set_preferences
    Spree::Config.avatax_api_username = ""
    Spree::Config.avatax_api_password = ""
    Spree::Config.avatax_company_code = "54321"
    Spree::Config.avatax_endpoint = "https://development.avalara.net"
    Spree::Config.avatax_account = ""
    Spree::Config.avatax_license_key = ""
    Spree::Config.avatax_log = true
    Spree::Config.avatax_address_validation = false
    Spree::Config.avatax_document_commit = true
    Spree::Config.avatax_tax_calculation = true
    Spree::Config.avatax_origin = "{\"Address1\":\"915 S Jackson St\",\"Address2\":\"\",\"City\":\"Montgomery\",\"Region\":\"Alabama\",\"Zip5\":\"36104\",\"Zip4\":\"\",\"Country\":\"United States\"}"
  end
end
