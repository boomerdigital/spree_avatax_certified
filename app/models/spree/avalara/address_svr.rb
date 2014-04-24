require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'

class AddressSvc
  @@service_path = '/1.0/address/'
  attr_accessor :account_number
  attr_accessor :license_key
  attr_accessor :service_url

  def initialize(account_number, license_key, service_url)
    @account_number = account_number
    @license_key = license_key
    @service_url = service_url
  end

  def Validate(address)
    return address if address.nil?
    encodedquery = Addressable::URI.new
    encodedquery.query_values = address
    uri = URI(@service_url + @@service_path  + "validate?"+ encodedquery.query)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    cred = 'Basic '+ Base64.encode64(@account_number + ":"+ @license_key)
    res = http.get(uri.request_uri, 'Authorization' => cred)
    JSON.parse(res.body)
  end

end