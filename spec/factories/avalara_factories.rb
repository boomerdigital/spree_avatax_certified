FactoryBot.define do
  factory :request_hash, class: Hash do
    Commit { false }
    CustomerCode { '1' }
    DocDate { '2014-11-03' }
    CompanyCode { '54321' }
    CustomerUsageType { '' }
    ExemptionNo { nil }
    Client { AVATAX_CLIENT_VERSION }
    DocCode { 'R731071205' }
    ReferenceCode { 'R731071205' }
    DetailLevel { 'Tax' }
    DocType { 'SalesOrder' }
    Discount { '0.00' }
    Addresses { [{:AddressCode=>'9', :Line1=>'31 South St', :City=>'Morristown', :PostalCode=>'07960', :Country=>'US'},{:AddressCode=>'Dest', :Line1=>'73 Glenmere Drive', :Line2=>'', :City=>'Chatham', :Region=>'NJ', :Country=>'US', :PostalCode=>'07928'},{:AddressCode=>'Orig', :Line1=>'73 Glenmere Drive', :City=>'Chatham', :PostalCode=>'07928', :Country=>'United States'}] }
    Lines { [{:LineNo=>'1-LI', :ItemCode=>'ROR-00013', :Qty=>3, :Amount=>62.97, :OriginCode=>'9', :DestinationCode=>'Dest', :Description=>'Ruby on Rails Jr. Spaghetti', :TaxCode=>'P0000000', :Discounted=>false}] }
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
