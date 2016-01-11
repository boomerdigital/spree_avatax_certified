require 'savon'

module SpreeAvataxCertified
  class SoapApi
    def initialize
      @username = Spree::Config.avatax_account
      @password = Spree::Config.avatax_license_key
      @service_url = Spree::Config.avatax_endpoint
      @clientname = AVATAX_CLIENT_VERSION

      spec = Gem::Specification.find_by_name('spree_avatax_certified')
      @name = 'test'
      @adapter = spec.summary + spec.version.to_s
      @machine = 'test'
      @ping_template = ERB.new(File.read("#{spec.gem_dir}/lib/spree_avatax_certified/templates/ping.erb"))
      @adjusttax_template = ERB.new(File.read("#{spec.gem_dir}/lib/spree_avatax_certified/templates/adjust_tax.erb"))
      @client = Savon.client(wsdl: 'https://development.avalara.net/tax/taxsvcaltsec.wsdl', endpoint: URI.parse(Spree::Config.avatax_endpoint + "/Tax/TaxSvc.asmx"))
    end

    def ping
      @soap = @ping_template.result(binding)
      @response = @client.call(:ping, xml: @soap).to_hash
    end

    def adjust_tax(request_hash)
      @AdjustmentReason = 4
      @AdjustmentDescription = 'test'

      request_hash.each_pair do |k,v|
        instance_variable_set("@#{k}",v)
      end

      @soap = @adjusttax_template.result(binding)
      @response = @client.call(:adjust_tax, xml: @soap).to_hash
    end
  end
end
