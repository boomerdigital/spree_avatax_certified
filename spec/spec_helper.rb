require 'simplecov'
SimpleCov.start do
  add_filter 'spec/dummy'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Models', 'app/models'
  add_group 'Views', 'app/views'
  add_group 'Libraries', 'lib'
end

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'dotenv'
Dotenv.load

require 'rspec/rails'
require 'database_cleaner'
require 'ffaker'
require 'shoulda/matchers'

require 'spree/testing_support/preferences'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/factories'

Dir[File.join(File.dirname(__FILE__), 'factories/*.rb')].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include Spree::TestingSupport::Preferences
  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::AuthorizationHelpers
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include FactoryBot::Syntax::Methods

  config.mock_with :rspec

  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  config.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
  end

  config.before :each do
    DatabaseCleaner.start
    MyConfigPreferences.set_preferences
  end

  config.after :each do
    DatabaseCleaner.clean
  end
end
