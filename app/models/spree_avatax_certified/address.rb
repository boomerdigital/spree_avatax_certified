require 'json'
require 'net/http'
require 'base64'
require 'logger'

module SpreeAvataxCertified
  class Address

    attr_reader :order, :addresses

    def initialize(order)
      @order = order
      @ship_address = order.ship_address
      @origin_address = JSON.parse(Spree::Config.avatax_origin)
      @stock_loc_ids = Spree::Stock::Coordinator.new(order).packages.map(&:to_shipment).map(&:stock_location_id)
      @addresses = []
      @logger ||= AvataxHelper::AvataxLog.new('avalara_order_addresses', 'SpreeAvataxCertified::Address', "Building Addresses for Order#: #{order.number}")
      build_addresses
      @logger.debug @addresses
    end

    def build_addresses
      origin_address
      order_ship_address unless @ship_address.nil?
      origin_ship_addresses
    end

    def origin_address
      addresses << {
        AddressCode: 'Orig',
        Line1: @origin_address['Address1'],
        Line2: @origin_address['Address2'],
        City: @origin_address['City'],
        Region: @origin_address['Region'],
        PostalCode: @origin_address['Zip5'],
        Country: @origin_address['Country']
      }
    end

    def order_ship_address
      addresses << {
        AddressCode: 'Dest',
        Line1: @ship_address.address1,
        Line2: @ship_address.address2,
        City: @ship_address.city,
        Region: @ship_address.state_name,
        Country: @ship_address.country.try(:iso),
        PostalCode: @ship_address.zipcode
      }
    end

    def origin_ship_addresses
      Spree::StockLocation.where(id: @stock_loc_ids).each do |stock_location|
        addresses << {
          AddressCode: "#{stock_location.id}",
          Line1: stock_location.address1,
          Line2: stock_location.address2,
          City: stock_location.city,
          PostalCode: stock_location.zipcode,
          Country: stock_location.country.try(:iso)
        }
      end
    end

    def validate
      return 'Address validation disabled' unless address_validation_enabled?
      return @ship_address if @ship_address.nil?

      address_hash = {
        Line1: @ship_address.address1,
        Line2: @ship_address.address2,
        City: @ship_address.city,
        Region: @ship_address.state.try(:abbr),
        Country: @ship_address.country.try(:iso),
        PostalCode: @ship_address.zipcode
      }

      validation_response(address_hash)
    end

    def country_enabled?
      enabled_countries.any? { |c| @ship_address.country.try(:name) == c }
    end

    private

    def validation_response(address)
      uri = URI(service_url + address.to_query)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.get(uri.request_uri, 'Authorization' => credential)

      response = JSON.parse(res.body)
      address = response['Address']

      if address['City'] == @ship_address.city || address['Region'] == @ship_address.state.abbr
      else
        response['ResultCode'] = 'Error'
        response['Messages'] = [
          {
            'Summary' => "Did you mean #{address['Line1']}, #{address['City']}, #{address['Region']}, #{address['PostalCode']}?"
          }
        ]
      end

      return response
    rescue => e
      "error in address validation: #{e}"
    end

    def address_validation_enabled?
      Spree::Config.avatax_address_validation && country_enabled?
    end

    def credential
      'Basic ' + Base64.encode64(account_number + ':' + license_key)
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

    def enabled_countries
      Spree::Config.avatax_address_validation_enabled_countries
    end
  end
end
