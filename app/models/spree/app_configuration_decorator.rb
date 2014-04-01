Spree::AppConfiguration.class_eval do
  preference :avatax_api_username, :string
  preference :avatax_api_password, :string
  preference :avatax_endpoint, :string
  preference :avatax_account, :string
  preference :avatax_servicepathtax, :string, default: '/1.0/tax/'
  preference :avatax_servicepathaddress, :string, default: '/1.0/address/'
  preference :avatax_license_key, :string
  preference :avatax_iseligible, :boolean, default: true
  preference :avatax_origin, :string, :default => {}.to_json
end

