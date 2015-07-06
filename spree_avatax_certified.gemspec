# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_avatax_certified'
  s.version     = '0.5.2'
  s.summary     = 'Spree extension for Avalara tax calculation.'
  s.description = 'Spree extension for Avalara tax calculation.'
  s.required_ruby_version = '>= 2.1.0'

  s.author    = 'Allison Reilly'
  s.email     = 'allison@railsdog.com'
  s.homepage  = 'http://railsdog.com'

  #s.files       = `git ls-files`.split("\n")
  #s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.0.0'
  s.add_dependency 'json', '~> 1.7'
  s.add_dependency 'addressable', '~> 2.3'
  s.add_dependency 'rest-client', '~> 1.7'
  s.add_dependency 'psych', '~> 2.0.4'
  s.add_dependency 'logging', '~> 1.8'

  #add gems here for files
  s.add_development_dependency 'deface'
  s.add_development_dependency 'capybara', '~> 2.4'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner', '~> 1.2'
  s.add_development_dependency 'factory_girl', '~> 4.5'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 3.1'
  s.add_development_dependency 'rspec-its', '~> 1.0'
  s.add_development_dependency 'sass-rails', '~> 5.0.0.beta1'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov', '~> 0.8'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'shoulda-matchers'
end
