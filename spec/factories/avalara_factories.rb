FactoryBot.define do
  factory :request_hash, class: Hash do
    createTransactionModel {{
      code: 'R250707809',
      date: '2017-05-31',
      discount: '0.0',
      commit: false,
      type: 'SalesOrder',
      lines: [
        {
          number: '1-LI',
          description: 'Product #1 - 1825',
          taxCode: 'PC030000',
          itemCode: 'SKU-1',
          quantity: 1,
          amount: 10.0,
          customerUsageType: nil,
          discounted: false,
          taxIncluded: false,
          addresses: {
            shipFrom: {
              line1: '1600 Pennsylvania Ave NW',
              line2: nil,
              city: 'Washington',
              region: 'DC',
              country: 'US',
              postalCode: '20500'},
            shipTo: {
              line1: '915 S Jackson St',
              line2: nil,
              city: 'Montgomery',
              region: 'AL',
              country: 'US',
              postalCode: '36104'
            }
          }
        }
      ],
      customerCode: 1,
      companyCode: '54321',
      customerUsageType: nil,
      exemptionNo: nil,
      referenceCode: 'R250707809',
      currencyCode: 'USD'
    }}

    initialize_with { attributes.deep_symbolize_keys }
  end

  factory :avalara_transaction_calculator, class: Spree::Calculator::AvalaraTransactionCalculator do
  end
end

FactoryBot.modify do
  factory :tax_category, class: Spree::TaxCategory do
    name { "TaxCategory - #{rand(999999)}" }
    tax_code { 'PC030000' }
  end

  factory :address, class: Spree::Address do
    transient do
      country_iso_code { 'US' }
      state_code { 'AL' }
    end

    firstname { 'John' }
    lastname { 'Doe' }
    company { 'Company' }
    address1 { '915 S Jackson St' }
    address2 { '' }
    city { 'Montgomery' }
    state_name { 'Alabama' }
    zipcode { '36104' }
    phone { '555-555-0199' }
    alternative_phone { '555-555-0199' }

    state do |address|
      if !Spree::State.find_by(name: address.state_name).nil?
        Spree::State.find_by(name: address.state_name)
      else
        address.association(:state, name: 'Alabama', abbr: 'AL')
      end
    end

    country do |address|
      if address.state
        address.state.country
      else
        address.association(:country, iso: country_iso_code)
      end
    end
  end

  factory :ship_address, parent: :address do
    address1 { '915 S Jackson St' }
  end

  # Adding this modifier since US country name changes between solidus versions
  factory :country, class: Spree::Country do
    iso_name { 'UNITED STATES' }
    name { 'United States' }
    iso { 'US' }
    iso3 { 'USA' }
    numcode { 840 }
  end
end
