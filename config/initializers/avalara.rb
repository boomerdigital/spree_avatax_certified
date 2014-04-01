
module AVALARA_CONFIG_Setup
  #AVALARA_CONFIG = YAML.load_file("#{::Rails.root}/config/avalara.yml")[::Rails.env]
end


#Avalara.configure do |config|
# config.username = AVALARA_CONFIG['username'] || abort("Avalara configuration file (#{path}) is missing the username value.")
# config.password = AVALARA_CONFIG['password'] || abort("Avalara configuration file (#{path}) is missing the password value.")
#config.version = AVALARA_CONFIG['version'] if AVALARA_CONFIGURATION.has_key?('version')
# config.endpoint = AVALARA_CONFIG['endpoint'] if AVALARA_CONFIGURATION.has_key?('endpoint')
#end
