require 'savon'

module SpreeAvataxCertified
  class SoapApi
    attr_reader :spec
    def initialize
      set_headers
      @client = Savon.client(wsdl: 'https://development.avalara.net/tax/taxsvcaltsec.wsdl', endpoint: URI.parse(Spree::Config.avatax_endpoint + '/Tax/TaxSvc.asmx'))
    end

    def ping
      @ping_template = ERB.new(File.read("#{spec.gem_dir}/lib/spree_avatax_certified/templates/ping.erb"))
      @soap = @ping_template.result(binding)
      @response = @client.call(:ping, xml: @soap).to_hash
    end

    def adjust_tax(request_hash)
      @AdjustmentReason = 4
      @AdjustmentDescription = 'Price or Quantity Adjusted'

      @adjust_tax_template = ERB.new(File.read("#{spec.gem_dir}/lib/spree_avatax_certified/templates/adjust_tax.erb"))

      request_hash.each_pair do |k,v|
        instance_variable_set("@#{k}", v)
      end

      @soap = @adjust_tax_template.result(binding)
      @response = @client.call(:adjust_tax, xml: @soap).to_hash
    end

    private

    def set_headers
      @username = Spree::Config.avatax_account
      @password = Spree::Config.avatax_license_key
      @service_url = Spree::Config.avatax_endpoint
      @clientname = AVATAX_CLIENT_VERSION
      @spec = Gem::Specification.find_by_name('spree_avatax_certified')
      @name = Rails.env
      @adapter = spec.summary + spec.version.to_s
      @machine = machine_name
    end

    def machine_name
      platform = RUBY_PLATFORM.downcase
      output = `#{(platform =~ /win32/) ? 'ipconfig /all' : 'ifconfig'}`
      case platform
      when /darwin/
        $1 if output =~ /en1.*?(([A-F0-9]{2}:){5}[A-F0-9]{2})/im
      when /win32/
        $1 if output =~ /Physical Address.*?(([A-F0-9]{2}-){5}[A-F0-9]{2})/im
      else
        ''
      end
    end
  end
end
