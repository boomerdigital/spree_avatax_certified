UNDER CONSTRUCTION
SpreeAvataxCertified
===========


Installation
------------
```ruby
gem 'spree_avatax_certified', github: 'railsdog/spree_avatax_certified', branch: '2-4-stable'
```
```shell
bundle install
```
```shell
bundle exec rails g spree_avatax_certified:install
```


Setup
-----

In the Spree Admin site configure the Avalara Setting.
[Imgur](http://i.imgur.com/aeX87y3.png)

Enter the Entity Use Codes that are configured in your Avalara site. If you chose to seed the use codes, these will already be set up for you.
[Imgur](http://i.imgur.com/nBo3E25.png)

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test_app
    $ bundle exec rspec spec

Copyright (c) 2014 RailsDog LLC, released under the New BSD License
