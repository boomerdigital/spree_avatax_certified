ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'rspec/rails'
require 'ffaker'
require 'factory_girl'
require 'database_cleaner'
require 'capybara/rspec'
require 'capybara/rails'
require 'shoulda/matchers'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

require 'spree/testing_support/preferences'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree_avatax/factories'

RSpec.configure do |config|
  config.include Spree::TestingSupport::Preferences
  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::AuthorizationHelpers
  config.include Spree::TestingSupport::ControllerRequests
  config.include FactoryGirl::Syntax::Methods

  config.mock_with :rspec

  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  DatabaseCleaner.strategy = :transaction

  config.before :each do
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
  end
end
