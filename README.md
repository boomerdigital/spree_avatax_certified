SpreeAvataxCertified
===========

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/railsdog/spree_avatax_certified?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Circle CI](https://circleci.com/gh/railsdog/spree_avatax_certified/tree/2-3-stable.svg?style=svg)](https://circleci.com/gh/railsdog/spree_avatax_certified/tree/2-3-stable)

SpreeAvataxCertified is the *only* [officially certified Avatax solution](http://www.avalara.com/avalara-certified/) that integrates with SpreeCommerce.  With this extension you can add instantaneous sales tax decisions to your store.

From Avalara's own explanation of the certification program:

> Relax. It’s certified.
>
> Our “Certified for AvaTax” Program features integrations that perform at the highest level, providing the best possible customer experience.

> Avalara’s partners who have created certified integrations for AvaTax have demonstrated that those integrations contain elements which are essential to providing customers with easy-to-use software that gives accurate sales tax calculations. The certification criteria used to demonstrate these elements are based on Avalara’s years of experience integrating into ERP, ecommerce and point-of-sale applications.


Installation
------------
```ruby
gem 'spree_avatax_certified', github: 'railsdog/spree_avatax_certified', branch: '2-3-stable'
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
![avatax_example](https://cloud.githubusercontent.com/assets/6445334/5670974/aedc85ec-9752-11e4-9bf6-23b7433fc7ab.png)

Enter the Entity Use Codes that are configured in your Avalara site. If you chose to seed the use codes, these will already be set up for you.
![avalara_entity_use_codes](https://cloud.githubusercontent.com/assets/6445334/5671017/f468e2d6-9752-11e4-8e53-efd95feeffb1.png)

Edit Tax Categories configuration settings. If left blank, the tax code will default to P0000000.
![taxcategories](https://cloud.githubusercontent.com/assets/6445334/5671227/2b840c18-9754-11e4-9f68-99efbfcc9fcd.png)

Make sure you have your tax rates set up for each tax category you have available on your site. If you use clothing, electronics, and shipping, there should be a tax rate for each of those.
![image](https://cloud.githubusercontent.com/assets/6445334/10485599/0c5d0d72-7259-11e5-888e-d09183f40851.png)
![image](https://cloud.githubusercontent.com/assets/6445334/10485617/218d0f94-7259-11e5-86d4-e1361e023841.png)

Edit the Shipping Methods configuration settings, to add Tax Category for each type of Shipping Method.
![image](https://cloud.githubusercontent.com/assets/6445334/10485517/a3f929f0-7258-11e5-86a3-e40de4585e4e.png)

Add Stock Location address. Without this, tax cannot calculate.
![image](https://cloud.githubusercontent.com/assets/6445334/10485464/573cb08c-7258-11e5-8d2f-c3f1a81abd01.png)

Configure specific users to utilize Avalara Entity Use Code, and Exemption number; Customer Code will be the user's id. Exemption Number are sourced from the Avalara site and the Avalara Entity Use code is a searchable drop down that was previously configured in the system.
![userinfoavalara](https://cloud.githubusercontent.com/assets/6445334/5671095/5e01cdca-9753-11e4-9900-6946c79ad614.png)

Load Seeds
----------
Will seed Avalara entity use codes and the basic tax calculators.
```shell
rake spree_avatax_certified:load_seeds
```


Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test_app
    $ bundle exec rspec spec

Copyright (c) 2014, 2015 RailsDog LLC, released under the New BSD License

# CHANGELOG
See [CHANGELOG.md](CHANGELOG.md) for change history.
