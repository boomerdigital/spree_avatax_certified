source 'http://rubygems.org'

branch = ENV.fetch('SPREE_BRANCH', '3-2-stable')
gem "spree", github: "spree/spree", branch: branch
gem "codeclimate-test-reporter", group: :test, require: nil

if branch == 'master' || branch >= "3-2-stable"
  gem "rails-controller-testing", group: :test
end

gem 'pry', group: [:test, :development]

gem 'pg'
gem 'mysql2'

gemspec
