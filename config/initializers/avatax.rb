# DO NOT MODIFY FILE
AVATAX_CLIENT_VERSION = "Spree Commerce by Boomer Digital; a0o0b000005cy4PA"
AVATAX_SERVICEPATH_ADDRESS = '/1.0/address/'
AVATAX_SERVICEPATH_TAX = '/1.0/tax/'
AVATAX_HEADERS = { 'X-Avalara-Client' => AVATAX_CLIENT_VERSION }.freeze

Spree::Config.avatax_company_code = ENV['AVATAX_COMPANY_CODE'] if ENV['AVATAX_COMPANY_CODE']
Spree::Config.avatax_account = ENV['AVATAX_ACCOUNT'] if ENV['AVATAX_ACCOUNT']
Spree::Config.avatax_license_key = ENV['AVATAX_LICENSE_KEY'] if ENV['AVATAX_LICENSE_KEY']
Spree::Config.avatax_endpoint = ENV['AVATAX_ENDPOINT'] if ENV['AVATAX_ENDPOINT']
