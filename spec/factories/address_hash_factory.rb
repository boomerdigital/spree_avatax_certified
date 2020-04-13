FactoryBot.define do
  # Request Hashes
  factory :address_hash, class: Hash do
    line1 { '915 S Jackson St' }
    city { 'Montgomery' }
    region { 'AL' }
    country { 'US' }
    postalCode { '36104' }

    initialize_with { attributes.stringify_keys }
  end

  # Response Hashes
  factory :address_validation_success, class: Hash do
    address {
      {
        'line1': '10 Mount Pleasant Ave',
        'city': 'Dover',
        'region': 'NJ',
        'country': 'US',
        'postalCode': '07801'
      }
    }
    validatedAddresses {
      [
        {
          'addressType': 'HighRiseOrBusinessComplex',
          'line1': '10 MOUNT PLEASANT AVE',
          'line2': '',
          'line3': '',
          'city': 'DOVER',
          'region': 'NJ',
          'country': 'US',
          'postalCode': '07801-1647',
          'latitude': 40.902378,
          'longitude': -74.5454
        }
      ]
    }
    coordinates {
      {
        'latitude': 40.902378,
        'longitude': -74.5454
      }
    }
    resolutionQuality { 'Intersection' }
    taxAuthorities {
      [
        {
          'avalaraId': '34',
          'jurisdictionName': 'NEW JERSEY',
          'jurisdictionType': 'State',
          'signatureCode': 'BEJY'
        }
      ]
    }

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :address_validation_error, class: Hash do
    error {
      {
        'code': 'ValidationException',
        'message': 'The address value was incomplete.',
        'target': 'IncorrectData',
        'details': [
          {
            'code': 'AddressIncomplete',
            'number': 309,
            'message': 'The address value was incomplete.',
            'description': 'The address value  was incomplete.  You must provide either a valid postal code, line1 + city + region, or latitude + longitude.  For international transactions outside of US/CA, only a country code is required.',
            'faultCode': 'Client',
            'helpLink': 'http://developer.avalara.com/avatax/errors/AddressIncomplete',
            'severity': 'Error'
          }
        ]
      }
    }

    initialize_with { attributes.deep_stringify_keys }
  end

  factory :address_validation_unknown, class: Hash do
    address {
      {
        'line1': '10 M',
        'city': 'D',
        'region': 'NJ',
        'country': 'US',
        'postalCode': '07'
      }
    }
    validatedAddresses {
      [
        {
          'addressType': 'UnknownAddressType',
          'line1': '10 M',
          'line2': '',
          'line3': '',
          'city': 'D',
          'region': 'NJ',
          'country': 'US',
          'postalCode': '07'
        }
      ]
    }
    resolutionQuality { 'External' }
    messages {
      [
        {
          'summary': 'The address is not deliverable.',
          'details': 'The physical location exists but there are no homes on this street. One reason might be railroad tracks or rivers running alongside this street, as they would prevent construction of homes in this location.',
          'refersTo': 'Address',
          'severity': 'Error',
          'source': 'Avalara.AvaTax.Services.Address'
        },
        {
          'summary': 'Address not geocoded.',
          'details': 'Address cannot be geocoded.',
          'refersTo': 'Address',
          'severity': 'Error',
          'source': 'Avalara.AvaTax.Services.Address'
        }
      ]
    }

    initialize_with { attributes.deep_stringify_keys }
  end
end
