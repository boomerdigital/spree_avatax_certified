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
end

FactoryGirl.modify do
  factory :tax_category, class: Spree::TaxCategory do
    name { "TaxCategory - #{rand(999999)}" }
    description { 'PC030000' }
  end
end
