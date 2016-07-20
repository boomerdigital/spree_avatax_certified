FactoryGirl.define do
  factory :request_hash, class: Hash do
    Commit false
    CustomerCode '1'
    DocDate '2014-11-03'
    CompanyCode '54321'
    CustomerUsageType ''
    ExemptionNo nil
    Client AVATAX_CLIENT_VERSION
    DocCode 'R731071205'
    ReferenceCode 'R731071205'
    DetailLevel 'Tax'
    DocType 'SalesOrder'
    Discount '0.00'
    Addresses [{:AddressCode=>'9', :Line1=>'31 South St', :City=>'Morristown', :PostalCode=>'07960', :Country=>'US'},{:AddressCode=>'Dest', :Line1=>'73 Glenmere Drive', :Line2=>'', :City=>'Chatham', :Region=>'NJ', :Country=>'US', :PostalCode=>'07928'},{:AddressCode=>'Orig', :Line1=>'73 Glenmere Drive', :City=>'Chatham', :PostalCode=>'07928', :Country=>'United States'}]
    Lines [{:LineNo=>'1-LI', :ItemCode=>'ROR-00013', :Qty=>3, :Amount=>62.97, :OriginCode=>'9', :DestinationCode=>'Dest', :Description=>'Ruby on Rails Jr. Spaghetti', :TaxCode=>'P0000000', :Discounted=>false}]
  end

  factory :avalara_transaction_calculator, class: Spree::Calculator::AvalaraTransactionCalculator do
  end

  factory :zone_member, class: Spree::ZoneMember do
    association :zoneable, factory: :country
  end

  factory :us_zone, class: Spree::Zone do
    name { "USA - #{rand(999999)}" }
    description { generate(:random_string) }
    transient do
      zone_members_count 1
    end
    after(:create) do |zone, evaluator|
      create_list(:zone_member, evaluator.zone_members_count, zone: zone)
    end
  end

  factory :avalara_tax_rate, class: Spree::TaxRate do
    association(:zone, factory: :us_zone, default_tax: true)
    amount 0.0
    tax_category
    association(:calculator, factory: :avalara_transaction_calculator)
  end
end

FactoryGirl.modify do
  factory :tax_category, class: Spree::TaxCategory do
    name { "TaxCategory - #{rand(999999)}" }
    description { 'PC030000' }
  end
end
