require 'spec_helper'

describe TaxSvc, :type => :model do
  MyConfigPreferences.set_preferences
  let(:taxsvc) { TaxSvc.new }
  let(:success_params) {
    code = rand(100000).to_s
    {:CustomerCode=>"1",:DocDate=>"2014-11-03",:CompanyCode=>"54321",:CustomerUsageType=>"",:ExemptionNo=>nil,:Client=>"SpreeExtV1.0",:DocCode=>code,:ReferenceCode=>code,:DetailLevel=>"Tax",:Commit=>false,:DocType=>"SalesInvoice",:Addresses=>[{:AddressCode=>9,:Line1=>"31 South St",:City=>"Morristown",:PostalCode=>"07960",:Country=>"US"},{:AddressCode=>"Dest",:Line1=>"73 Glenmere Drive",:Line2=>"",:City=>"Chatham",:Region=>"NJ",:Country=>"US",:PostalCode=>"07928"},{:AddressCode=>"Orig",:Line1=>"73 Glenmere Drive",:City=>"Chatham",:PostalCode=>"07928",:Country=>"United States"}],:Lines=>[{:LineNo=>1,:ItemCode=>"ROR-00013",:Qty=>3,:Amount=>62.97,:OriginCode=>9,:DestinationCode=>"Dest",:Description=>"Ruby on Rails Jr. Spaghetti",:TaxCode=>""}]}
  }
  describe "#get_tax" do
    it "gets tax when all credentials are there" do
      result = taxsvc.get_tax(success_params)
      expect(result["ResultCode"]).to eq("Success")
    end

    context 'fails' do
      it 'fails when no params are given' do
        expect(taxsvc.get_tax({})).to eq('error in Tax')
      end

      it 'responds with error when result code is not a success' do
        result = taxsvc.get_tax(
        {:CustomerCode=>"1",:DocDate=>"2014-11-03",:CompanyCode=>"54321",:CustomerUsageType=>"",:ExemptionNo=>nil,:Client=>"SpreeExtV1.0",:DocCode=>"R731071205",:ReferenceCode=>"R731071205",:DetailLevel=>"Tax",:Commit=>false,:DocType=>"SalesInvoice",:Addresses=>[{:AddressCode=>9,:Line1=>"31 South St",:City=>"Morristown",:PostalCode=>"07960",:Country=>"US"},{:AddressCode=>"Dest",:Line1=>"",:Line2=>"",:City=>"Chatham",:Region=>"NJ",:Country=>"US",:PostalCode=>"07928"},{:AddressCode=>"Orig",:Line1=>"73 Glenmere Drive",:City=>"Chatham",:PostalCode=>"07928",:Country=>"United States"}],:Lines=>[{:LineNo=>1,:ItemCode=>"ROR-00013",:Qty=>3,:Amount=>62.97,:OriginCode=>9,:DestinationCode=>"Dest",:Description=>"Ruby on Rails Jr. Spaghetti",:TaxCode=>"sdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdf"}]}
        )
        expect(result).to eq('error in Tax')
      end

      it 'fails when no lines are given' do
        expect(taxsvc.get_tax({:CustomerCode=>"1",:DocDate=>"2014-11-03",:CompanyCode=>"54321",:CustomerUsageType=>"",:ExemptionNo=>nil,:Client=>"SpreeExtV1.0",:DocCode=>"R731071205",:ReferenceCode=>"R731071205",:DetailLevel=>"Tax",:Commit=>false,:DocType=>"SalesInvoice",:Addresses=>[{:AddressCode=>9,:Line1=>"31 South St",:City=>"Morristown",:PostalCode=>"07960",:Country=>"US"},{:AddressCode=>"Dest",:Line1=>"73 Glenmere Drive",:Line2=>"",:City=>"Chatham",:Region=>"NJ",:Country=>"US",:PostalCode=>"07928"},{:AddressCode=>"Orig",:Line1=>"73 Glenmere Drive",:City=>"Chatham",:PostalCode=>"07928",:Country=>"United States"}]})).to eq('error in Tax')
      end
    end
  end

  describe "#cancel_tax" do
    it "should raise error" do
      result = taxsvc.cancel_tax({
        :CompanyCode=> "54321",
        :DocType => "SalesInvoice",
        :CancelCode => "DocVoided"
        })
      expect(result['ResultCode']).to eq('Error')
    end

    it 'respond with success' do
      success_res = taxsvc.get_tax(success_params)
      result = taxsvc.cancel_tax({
        :CompanyCode=> "54321",
        :DocType => "SalesInvoice",
        :DocCode => success_params[:DocCode],
        :CancelCode => "DocVoided"
      })

      expect(result['ResultCode']).to eq('Success')
    end
  end

  describe "#ping" do
    it "should return estimate" do
      result = taxsvc.ping
      expect(result["ResultCode"]).to eq("Success")
    end
  end
end

