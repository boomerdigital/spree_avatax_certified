require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'
require 'rest-client'
require 'logging'

class TaxSvc
  @@service_path = "/1.0/tax/"
  attr_accessor :account_number
  attr_accessor :license_key
  attr_accessor :service_url
  logger.progname = 'tax_service'
  logger.info 'call to tax service'

  def initialize
    @account_number = Spree::Config.avatax_account
    @license_key    = Spree::Config.avatax_license_key
    @service_url    = Spree::Config.avatax_endpoint
  end

  def get_tax(request_hash)
    logger.info 'get_tax call'
    logger.debug request_hash
    logger.debug JSON.generate(request_hash)

    begin
      uri = @service_url + @@service_path + "get"
      logger.debug uri
      cred = 'Basic '+ Base64.encode64(@account_number + ":"+ @license_key)
      logger.debug cred
      RestClient.log = logger
      res = RestClient.post(uri, JSON.generate(request_hash), :authorization => cred, :content_type => 'application/json'){|response, request, result| response}
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
      uri = @service_url + @@service_path + "cancel"
      cred = 'Basic '+ Base64.encode64(@account_number + ":"+ @license_key)
      res = RestClient.post(uri, JSON.generate(request_hash), :authorization => cred, :content_type => 'application/json'){|response, request, result| response}
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
      uri = URI(@service_url + @@service_path  +
        coordinates[:latitude].to_s + "," + coordinates[:longitude].to_s +
        "/get?saleamount=" + sale_amount.to_s )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      cred = 'Basic '+ Base64.encode64(@account_number + ":"+ @license_key)
      res = http.get(uri.request_uri, 'Authorization' => cred, 'Content-Type' => 'application/json')
      JSON.parse(res.body)
    rescue => e
      debug 'error in Estimate Tax'
    end
  end

  def ping
    logger.info 'Ping Call'

    self.estimate_tax(
      { :latitude => "40.714623",
        :longitude => "-74.006605"},
        0 )
  end

  private

  def logger
    Logger.new('log/tax_svc.txt', 'weekly')
  end

  def debug(text)
    logger.debug e
    logger.debug text
    text
  end
end
