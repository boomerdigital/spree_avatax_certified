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
  @@logger = Logger.new('log/tax_svc.txt', 'weekly')

  #logger.level = :debug

  @@logger.progname = 'tax_service'
  @@logger.info 'call to tax service'



  def initialize(account_number, license_key, service_url)
    @account_number = account_number
    @license_key = license_key
    @service_url = service_url
  end

  def GetTax(request_hash)
    logger = Logger.new('log/tax_svc.txt', 'weekly')
    logger.info 'GetTax call'
    logger.debug request_hash
    begin
      uri = @service_url + @@service_path + "get"
      logger.debug uri
      cred = 'Basic '+ Base64.encode64(@account_number + ":"+ @license_key)
      logger.debug cred
      RestClient.log = logger
      res = RestClient.post uri, JSON.generate(request_hash), :authorization => cred
      logger.debug res
      JSON.parse(res.body)
    rescue => e
      logger.debug e
      logger.debug 'error in Tax'
      'error in Tax'
    end
  end


  def CancelTax(request_hash)
    logger = Logger.new('log/tax_svc.txt', 'weekly')
    logger.info 'CancelTax call'
    begin
    uri = @service_url + @@service_path + "cancel"
    cred = 'Basic '+ Base64.encode64(@account_number + ":"+ @license_key)
    res = RestClient.post uri, JSON.generate(request_hash), :authorization => cred
    logger.debug res
    JSON.parse(res.body)["CancelTaxResult"]
    rescue => e
      logger.debug e
      logger.debug 'error in Estimate Tax'
      'error in Estimate Tax'
    end
    #You may notice that this is slightly different from CalcTax, etc. The CancelTax result is  nested in this result object - this makes it consumable in a way that is consistant with the other response formats.
  end

  def EstimateTax(coordinates, sale_amount)
    # coordinates should be a hash with latitude and longitude
    # sale_amount should be a decimal
    logger = Logger.new('log/tax_svc.txt', 'weekly')
    logger.info 'EstimateTax call'
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
    res = http.get(uri.request_uri, 'Authorization' => cred)
    #logger.debug res
    JSON.parse(res.body)
    rescue => e
      logger.debug e
      logger.debug 'error in Estimate Tax'
      'error in Estimate Tax'
    end
  end

  def Ping
    #There is no actual ping in the REST API, so this is a mockup that calls EstimateTax with
    #hardcoded values.
    logger = Logger.new('log/tax_svc.txt', 'weekly')
    logger.info 'Ping Call'
    self.EstimateTax(
        { :latitude => "40.714623",
          :longitude => "-74.006605"},
        0 )
  end

end