require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'
require 'rest-client'
require 'logging'
# Avatax tax calculation API calls

module Spree
  class TaxSvc
    def get_tax(request_hash)
      log(__method__, request_hash)

      req = client.transactions.create_or_adjust(request_hash)

      response = SpreeAvataxCertified::Response::GetTax.new(req)

      handle_response(response)
    end

    def cancel_tax(transaction_code)
      log(__method__, transaction_code)

      req = client.transactions.void(company_code, transaction_code)
      response = SpreeAvataxCertified::Response::CancelTax.new(req)

      handle_response(response)
    end

    def ping
      logger.info 'Ping Call'

      # Testing if configuration is set up properly, ping will fail if it is not
      client.tax_rates.get(:by_postal_code, country: 'US', postalCode: '07801')
    end


    def validate_address(address)
      begin
        request = client.addresses.validate(address)
      rescue StandardError => e
        logger.error(e)

        request = { 'error' => { 'message' => e } }
      end

      response = SpreeAvataxCertified::Response::AddressValidation.new(request)
      handle_response(response)
    end

    protected

    def handle_response(response)
      result = response.result
      begin
        if response.error?
          raise SpreeAvataxCertified::RequestError, result
        end

        logger.debug(result, response.description + ' Response')
      rescue SpreeAvataxCertified::RequestError => e
        logger.error(e.message, response.description + ' Error')
        raise if raise_exceptions?
      end

      response
    end

    def logger
      @logger ||= SpreeAvataxCertified::AvataxLog.new('TaxSvc class', 'Call to tax service')
    end

    private

    def tax_calculation_enabled?
      Spree::Config.avatax_tax_calculation
    end

    def credential
      'Basic ' + Base64.encode64(account_number + ':' + license_key)
    end

    def service_url
      Spree::Config.avatax_endpoint + AVATAX_SERVICEPATH_TAX
    end

    def address_service_url
      Spree::Config.avatax_endpoint + AVATAX_SERVICEPATH_ADDRESS + 'validate?'
    end

    def license_key
      Spree::Config.avatax_license_key
    end

    def account_number
      Spree::Config.avatax_account
    end

    def company_code
      Spree::Config.avatax_company_code
    end

    def environment
      Rails.env.production? ? :production : :sandbox
    end

    def raise_exceptions?
      Spree::Config.avatax_raise_exceptions
    end

    def client
      @client ||= Avatax::Client.new(
        username: account_number,
        password: license_key,
        env: environment,
        headers: AVATAX_HEADERS
      )
    end

    def log(method, request_hash = nil)
      return if request_hash.nil?
      logger.debug(request_hash, "#{method.to_s} request hash")
    end
  end
end
