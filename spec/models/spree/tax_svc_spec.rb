require 'rails_helper'

describe TaxSvc do
  describe "get_tax" do
    it "gets tax" do
      taxsvc = TaxSvc.new(Spree::Config.avatax_account, Spree::Config.avatax_license, Spree::Config.avatax_endpoint)
      taxsvc.get_tax(
        { :CustomerCode => "1",
          :DocDate => "2014-11-03",
          :CompanyCode => "54321",
          :CustomerUsageType => "",
          :ExemptionNo => nil,
          :Client => "SpreeExtV1.0",
          :DocCode => "R731071205",
          :ReferenceCode => "R731071205",
          :DetailLevel => "Tax",
          :Commit => false,
          :DocType => "SalesInvoice",
          :Addresses => [
            {
              :AddressCode => 9,
              :Line1 => "31 South St",
              :City => "Morristown",
              :PostalCode => "07960",
              :Country => "US"
            },
            {
              :AddressCode => "Dest",
              :Line1 => "73 Glenmere Drive",
              :Line2 => "",
              :City => "Chatham",
              :Region => "NJ",
              :Country => "US",
              :PostalCode => "07928"
            },
            {
              :AddressCode => "Orig",
              :Line1 => "73 Glenmere Drive",
              :City => "Chatham",
              :PostalCode => "07928",
              :Country => "United States"
            }
          ],
          :Lines => [
            {
              :LineNo => 1,
              :ItemCode => "ROR-00013",
              :Qty => 3,
              :Amount => 62.97,
              :OriginCode => 9,
              :DestinationCode => "Dest",
              :Description => "Ruby on Rails Jr. Spaghetti",
              :TaxCode => ""
            }
          ]
        }
      )
    end
  end
end

