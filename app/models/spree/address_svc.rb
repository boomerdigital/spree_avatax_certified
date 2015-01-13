require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'

class AddressSvc

  def validate(address)
    if address_validation_enabled? && country_enabled?(Spree::Country.find(address[:country_id]))

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

      response = JSON.parse(res.body)

      if response["Address"]["City"] == address[:city] || response["Address"]["Region"] == Spree::State.find(address[:state_id]).abbr
        return response
      else
        response["ResultCode"] = "Error"
        suggested_address = response["Address"]
        response["Messages"] = [{
          "Summary" => "Did you mean #{suggested_address['Line1']}, #{suggested_address['City']}, #{suggested_address['Region']}, #{suggested_address['PostalCode']}?"
          }]
          return response
        end
      else
        "Address validation disabled"
      end
    rescue => e
      'error in address validation'
    end

    def address_validation_enabled?
      Spree::Config.avatax_address_validation
    end

    def country_enabled?(current_country)
      Spree::Config.avatax_address_validation_enabled_countries.each do |country|
        if current_country.name == country
          return true
        else
          false
        end
      end
    end

    private

    def credential
      'Basic ' + Base64.encode64(account_number + ":" + license_key)
    end

    def service_url
      Spree::Config.avatax_endpoint + AVATAX_SERVICEPATH_ADDRESS + 'validate?'
    end

    def license_key
      Spree::Config.avatax_license_key
    end

    def account_number
      Spree::Config.avatax_account
    end
  end