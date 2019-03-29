require 'json'
require 'net/http'
require 'base64'

module SpreeAvataxCertified
  class Address
    attr_reader :order, :addresses

    def initialize(order)
      @order = order
      @ship_address = order.ship_address
      @origin_address = JSON.parse(Spree::Config.avatax_origin)
      @addresses = {}

      build_addresses
    end

    def build_addresses
      origin_address
      order_ship_address unless @ship_address.nil?
    end

    def origin_address
      addresses[:pointOfOrderAcceptance] = {
        line1: @origin_address['line1'],
        line2: @origin_address['line2'],
        city: @origin_address['city'],
        region: @origin_address['region'],
        country: @origin_address['country'],
        postalCode: @origin_address['postalCode']
      }
    end

    def order_ship_address
      addresses[:shipTo] = @ship_address.to_avatax_hash
    end

    def validate
      return 'Address validation disabled' unless @ship_address.validation_enabled?
      return @ship_address if @ship_address.nil?

      validation_response(@ship_address.to_avatax_hash)
    end

    private

    def validation_response(address)
      validator = TaxSvc.new
      validator.validate_address(address)
    end
  end
end
