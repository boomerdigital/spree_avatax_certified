require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'
require 'rest-client'
require 'logging'

class TaxSvc
  include AvataxHelper
  def get_tax(request_hash)
    log(__method__, request_hash)
    RestClient.log = logger.logger
    res = response("get", request_hash)
    logger.info 'RestClient call'
    logger.debug res
    JSON.parse(res.body)
  rescue => e
    logger.info 'Rest Client Error'
    logger.debug e, 'error in Tax'
  end

  def cancel_tax(request_hash)
    log(__method__, request_hash)
    res = response("cancel", request_hash)
    logger.debug res
    JSON.parse(res.body)["CancelTaxResult"]
  rescue => e
    logger.debug e, 'error in Cancel Tax'
  end

  def estimate_tax(coordinates, sale_amount)
    log(__method__)

    return nil if coordinates.nil?
    sale_amount = 0 if sale_amount.nil?

    begin
      uri = URI(service_url + coordinates[:latitude].to_s + "," + coordinates[:longitude].to_s + "/get?saleamount=" + sale_amount.to_s )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      res = http.get(uri.request_uri, 'Authorization' => credential, 'Content-Type' => 'application/json')
      JSON.parse(res.body)
    rescue => e
      logger.debug e, 'error in Estimate Tax'
    end
  end

  def ping
    logger.info 'Ping Call'
    self.estimate_tax({ latitude: "40.714623", longitude: "-74.006605"}, 0)
  end

  protected

  def logger
    AvataxLog.new("tax_svc", "tax_service", 'call to tax service')
  end

  private

  def credential
    'Basic ' + Base64.encode64(account_number + ":" + license_key)
  end

  def service_url
    Spree::Config.avatax_endpoint + '/1.0/tax/'
  end

  def license_key
    Spree::Config.avatax_license_key
  end

  def account_number
    Spree::Config.avatax_account
  end

  def response(uri, request_hash)
    RestClient.post(service_url + uri, JSON.generate(request_hash), authorization: credential, content_type: 'application/json') do |response, request, result|
      response
    end
  end

  def log(method, request_hash = nil)
    logger.info method.to_s + ' call'
    unless request_hash.nil?
      logger.debug request_hash
      logger.debug JSON.generate(request_hash)
    end
  end
end
