module SpreeAvataxCertified
  class Engine < Rails::Engine
    require 'spree/core'
    require 'spree/backend'
    isolate_namespace Spree
    engine_name 'spree_avatax_certified'

    config.autoload_paths += %W(#{config.root}/lib)

    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/models/**/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
