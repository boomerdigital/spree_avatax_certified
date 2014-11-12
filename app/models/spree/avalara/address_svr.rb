require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'

class AddressSvc

  def validate(address)
    return address if address.nil?

    address_hash = {
      Line1: address[:address1],
      Line2: address[:address2],
      City: address[:city],
      Region: Spree::State.find(address[:state_id]).abbr,
      Country: Spree::Country.find(address[:country_id]).iso,
      PostalCode: address[:zipcode]
    }

    encodedquery = Addressable::URI.new
    encodedquery.query_values = address_hash
    uri = URI(service_url + encodedquery.query)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    res = http.get(uri.request_uri, 'Authorization' => credential)
    JSON.parse(res.body)
  rescue => e
    'error in address validation'
  end


  private

  def credential
    'Basic ' + Base64.encode64(account_number + ":" + license_key)
  end

  def service_url
    Spree::Config.avatax_endpoint + '/1.0/address/validate?'
  end

  def license_key
    Spree::Config.avatax_license_key
  end

  def account_number
    Spree::Config.avatax_account
  end
end