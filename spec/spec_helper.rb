ENV['RAILS_ENV'] ||= 'test'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'dotenv'
Dotenv.load

require 'rspec/rails'
require 'rspec/its'
require 'ffaker'
require 'factory_girl'
require 'database_cleaner'
require 'capybara/rspec'
require 'capybara/rails'
require 'shoulda/matchers'

require 'spree/testing_support/preferences'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/factories'
require 'spree_avatax_certified/factories'
require 'factories/avalara_factories'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include Spree::TestingSupport::Preferences
  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::AuthorizationHelpers
  config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.include FactoryGirl::Syntax::Methods

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
