require 'json'
require 'net/http'
require 'addressable/uri'
require 'base64'
require 'rest-client'
require 'logging'

# Avatax tax calculation API calls
class TaxSvc
  def get_tax(request_hash)
    log(__method__, request_hash)
    RestClient.log = logger.logger
    res = response('get', request_hash)
    logger.info_and_debug('RestClient call', res)

    if res['ResultCode'] != 'Success'
      logger.info 'Avatax Error'
      logger.debug res, 'error in Tax'
      raise 'error in Tax'
    else
      res
    end
  rescue => e
    logger.info 'Rest Client Error'
    logger.debug e, 'error in Tax'
    'error in Tax'
  end

  def cancel_tax(request_hash)
    if tax_calculation_enabled?
      log(__method__, request_hash)
      res = response('cancel', request_hash)
      logger.debug res
      res['CancelTaxResult']
    end
  rescue => e
    logger.debug e, 'error in Cancel Tax'
    'error in Cancel Tax'
  end

  def estimate_tax(coordinates, sale_amount)
    if tax_calculation_enabled?
      log(__method__)

      return nil if coordinates.nil?
      sale_amount = 0 if sale_amount.nil?
      coor = coordinates[:latitude].to_s + ',' + coordinates[:longitude].to_s

      uri = URI(service_url + coor + '/get?saleamount=' + sale_amount.to_s)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      res = http.get(uri.request_uri, 'Authorization' => credential, 'Content-Type' => 'application/json')
      JSON.parse(res.body)
    end
  rescue => e
    logger.debug e, 'error in Estimate Tax'
    'error in Estimate Tax'
  end

  def ping
    logger.info 'Ping Call'
    estimate_tax({ latitude: '40.714623', longitude: '-74.006605' }, 0)
  end

  protected

  def logger
    AvataxHelper::AvataxLog.new('tax_svc', 'tax_service', 'call to tax service')
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

  def license_key
    Spree::Config.avatax_license_key
  end

  def account_number
    Spree::Config.avatax_account
  end

  def response(uri, request_hash)
    url = service_url + uri
    res = RestClient.post(url, JSON.generate(request_hash), authorization: credential, content_type: 'application/json') do |response|
      response
    end
    JSON.parse(res)
  end

  def log(method, request_hash = nil)
    logger.info method.to_s + ' call'
    return if request_hash.nil?
    logger.debug request_hash
    logger.debug JSON.generate(request_hash)
  end
end
