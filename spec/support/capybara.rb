require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'capybara/rails'
require 'webdrivers/chromedriver'
require 'selenium/webdriver'


Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(
      args: %w[no-sandbox disable-dev-shm-usage disable-popup-blocking headless disable-gpu window-size=1920,1080 --enable-features=NetworkService,NetworkServiceInProcess --disable-features=VizDisplayCompositor],
      log_level: :error
    )
end

Capybara.javascript_driver = :chrome
