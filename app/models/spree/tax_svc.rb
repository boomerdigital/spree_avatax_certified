require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'
require 'rest-client'
require 'logging'

class TaxSvc
  logger.progname = 'tax_service'
  logger.info 'call to tax service'

  def initialize() end

  def get_tax(request_hash)
    logger.info 'get_tax call'
    logger.debug request_hash
    logger.debug JSON.generate(request_hash)

    begin
      uri = service_url + "get"
      logger.debug uri
      cred = 'Basic '+ Base64.encode64(account_number + ":" + license_key)
      logger.debug cred
      RestClient.log = logger
      res = response(uri, request_hash, cred)
      logger.info 'RestClient call'
      logger.debug res
      JSON.parse(res.body)
    rescue => e
      logger.info 'Rest Client Error'
      debug 'error in Tax'
    end
  end


  def cancel_tax(request_hash)
    logger.info 'cancel_tax call'
    begin
      uri = service_url + "cancel"
      cred = 'Basic '+ Base64.encode64(account_number + ":" + license_key)
      res = response(uri, request_hash, cred)
      logger.debug res
      JSON.parse(res.body)["CancelTaxResult"]
    rescue => e
      debug 'error in Estimate Tax'
    end
  end

  def estimate_tax(coordinates, sale_amount)
    # coordinates should be a hash with latitude and longitude
    # sale_amount should be a decimal
    logger.info 'estimate_tax call'

    return nil if coordinates.nil?
    sale_amount = 0 if sale_amount.nil?

    begin
      uri = URI(service_url +
        coordinates[:latitude].to_s + "," + coordinates[:longitude].to_s +
        "/get?saleamount=" + sale_amount.to_s )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      cred = 'Basic '+ Base64.encode64(account_number + ":" + license_key)
      res = http.get(uri.request_uri, 'Authorization' => cred, 'Content-Type' => 'application/json')
      JSON.parse(res.body)
    rescue => e
      debug 'error in Estimate Tax'
    end
  end

  def ping
    logger.info 'Ping Call'
    self.estimate_tax({ latitude: "40.714623", longitude: "-74.006605"}, 0)
  end

  private

  def service_url
    Spree::Config.avatax_endpoint + '/1.0/tax/'
  end

  def license_number
    Spree::Config.avatax_license_key
  end

  def account_number
    Spree::Config.avatax_account
  end

  def response(uri, request_hash, cred)
    RestClient.post(uri, JSON.generate(request_hash), authorization: cred, content_type: 'application/json') do |response, request, result|
      response
    end
  end

  def logger
    Logger.new('log/tax_svc.txt', 'weekly')
  end

  def debug(text)
    logger.debug e
    logger.debug text
    text
  end
end
