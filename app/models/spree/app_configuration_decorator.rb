Spree::AppConfiguration.class_eval do
  preference :avatax_api_username, :string
  preference :avatax_api_password, :string
  preference :avatax_company_code, :string
  preference :avatax_endpoint, :string
  preference :avatax_account, :string
  preference :avatax_license_key, :string
  preference :avatax_iseligible, :boolean, default: true
  preference :avatax_log, :boolean, default: true
  preference :avatax_origin, :string, default: {}
end
