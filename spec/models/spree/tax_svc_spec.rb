require 'spec_helper'

describe TaxSvc, :type => :model do
  describe "GetTax" do
    it "gets tax" do
      taxsvc = TaxSvc.new(ENV['AVALARA_ACCOUNT'], ENV['AVALARA_LISENCE_KEY'], ENV['AVALARA_ENDPOINT'])
      taxsvc.GetTax({:CustomerCode=>"1", :DocDate=>"2014-11-03", :CompanyCode=>"54321", :CustomerUsageType=>"", :ExemptionNo=>nil, :Client=>"SpreeExtV1.0", :DocCode=>"R731071205", :ReferenceCode=>"R731071205", :DetailLevel=>"Tax", :Commit=>false, :DocType=>"SalesInvoice", :Addresses=>[{:AddressCode=>9, :Line1=>"31 South St", :City=>"Morristown", :PostalCode=>"07960", :Country=>"US"}, {:AddressCode=>"Dest", :Line1=>"73 Glenmere Drive", :Line2=>"", :City=>"Chatham", :Region=>"NJ", :Country=>"US", :PostalCode=>"07928"}, {:AddressCode=>"Orig", :Line1=>"73 Glenmere Drive", :City=>"Chatham", :PostalCode=>"07928", :Country=>"United States"}], :Lines=>[{:LineNo=>1, :ItemCode=>"ROR-00013", :Qty=>3, :Amount=>62.97, :OriginCode=>9, :DestinationCode=>"Dest", :Description=>"Ruby on Rails Jr. Spaghetti", :TaxCode=>""}]})

    end
  end
end

