require 'spec_helper'

describe TaxSvc, :type => :model do
  let(:taxsvc) { TaxSvc.new }
  let(:request_hash) { attributes_for(:request_hash) }

  describe "#get_tax" do
    it "gets tax when all credentials are there" do
      result = taxsvc.get_tax(request_hash)
      expect(result["ResultCode"]).to eq("Success")
    end

    context 'fails' do
      it 'fails when no params are given' do
        expect(taxsvc.get_tax({})).to eq('error in Tax')
      end

      it 'fails when no lines are given' do
        expect(taxsvc.get_tax(attributes_for(:request_hash, Lines: []))).to eq('error in Tax')
      end
    end
  end

  describe "#cancel_tax" do
    it "should raise error" do
      result = taxsvc.cancel_tax({
        :CompanyCode=> "54321",
        :DocType => "SalesInvoice",
        :DocCode => "INV001",
        :CancelCode => "DocVoided"
        })
      expect(result["ResultCode"]).to eq("Error")
    end
  end

  describe "#ping" do
    it "should return estimate" do
      result = taxsvc.ping
      expect(result["ResultCode"]).to eq("Success")
    end
  end
end

