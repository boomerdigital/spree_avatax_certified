SpreeAvatax
===========

For help getting started, please see the wiki: https://github.com/railsdog/spree_avatax_certified/wiki/Getting-Started

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test_app

    # obtain Avatax test credentials and populate the preferences file
    $ cp support/config_preferences.example.rb support/config_preferences.rb
    $ bundle exec rspec spec

Copyright (c) 2014 RailsDog LLC, released under the New BSD License
