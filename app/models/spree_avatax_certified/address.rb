require 'json'
require 'net/http'
require 'base64'
require 'logger'

module SpreeAvataxCertified
  class Address
    attr_reader :order, :addresses, :origin_address, :stock_addresses

    def initialize(order)
      @order = order
      @ship_address = order.ship_address
      @origin_address = JSON.parse(Spree::Config.avatax_origin)
      @stock_loc_ids = Spree::Stock::Coordinator.new(order).packages.map(&:to_shipment).map(&:stock_location_id)
      @stock_addresses = []
      @addresses = []
      @logger ||= AvataxHelper::AvataxLog.new('avalara_order_addresses', 'SpreeAvataxCertified::Address', 'building addresses')
      build_addresses
      @logger.debug @addresses
    end

    def build_addresses
      origin_address
      order_ship_address unless @ship_address.nil?
      origin_ship_addresses
    end

    def origin_address
      orig_address = {
        AddressCode: 'Orig',
        Line1: @origin_address['Address1'],
        Line2: @origin_address['Address2'],
        City: @origin_address['City'],
        Region: @origin_address['Region'],
        PostalCode: @origin_address['Zip5'],
        Country: @origin_address['Country']
      }

      addresses << orig_address
    end

    def order_ship_address
      shipping_address = {
        AddressCode: 'Dest',
        Line1: @ship_address.address1,
        Line2: @ship_address.address2,
        City: @ship_address.city,
        Region: @ship_address.state_name,
        Country: Spree::Country.find(@ship_address.country_id).iso,
        PostalCode: @ship_address.zipcode
      }

      addresses << shipping_address
    end

    def origin_ship_addresses
      Spree::StockLocation.where(id: @stock_loc_ids).each do |stock_location|
        stock_location_address = {
          AddressCode: "#{stock_location.id}",
          Line1: stock_location.address1,
          Line2: stock_location.address2,
          City: stock_location.city,
          PostalCode: stock_location.zipcode,
          Country: Spree::Country.find(stock_location.country_id).iso
        }

        @stock_addresses << stock_location_address
      end
    end

    def validate
      country = Spree::Country.find(@ship_address[:country_id])
      if address_validation_enabled? && country_enabled?(country)

        return @ship_address if @ship_address.nil?

        address_hash = {
          Line1: @ship_address[:address1],
          Line2: @ship_address[:address2],
          City: @ship_address[:city],
          Region: Spree::State.find(@ship_address[:state_id]).abbr,
          Country: Spree::Country.find(@ship_address[:country_id]).iso,
          PostalCode: @ship_address[:zipcode]
        }

        return validation_response(address_hash)
      else
        'Address validation disabled'
      end
    end

    def country_enabled?(current_country)
      enabled_countries.any? { |c| current_country.name == c }
    end

    private

    def validation_response(address)
      uri = URI(service_url + address.to_query)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.get(uri.request_uri, 'Authorization' => credential)

      response = JSON.parse(res.body)

      if response['Address']['City'] == @ship_address[:city] || response['Address']['Region'] == Spree::State.find(@ship_address[:state_id]).abbr
        return response
      else
        response['ResultCode'] = 'Error'
        suggested_address = response['Address']
        response['Messages'] = [
          {
            'Summary' => "Did you mean #{suggested_address['Line1']}, #{suggested_address['City']}, #{suggested_address['Region']}, #{suggested_address['PostalCode']}?"
          }
        ]
        return response
      end
    rescue => e
      "error in address validation: #{e}"
    end

    def address_validation_enabled?
      Spree::Config.avatax_address_validation
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
